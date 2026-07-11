import { AwsClient } from 'aws4fetch';
import { createRemoteJWKSet, jwtVerify } from 'jose';

// ─── Environment ─────────────────────────────────────────────────────────────

type Env = {
  FIREBASE_PROJECT_ID: string;
  R2_ACCOUNT_ID: string;
  R2_BUCKET_NAME: string;
  R2_PUBLIC_BASE_URL: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  ALLOWED_ORIGIN?: string;
};

// ─── Types ────────────────────────────────────────────────────────────────────

type UploadType = 'avatar' | 'circleCover' | 'messagePhoto' | 'pulsePhoto';

type SignRequest = {
  type?: UploadType;
  contentType?: string;
  fileExtension?: string;
  circleId?: string;
  contentLength?: number;
};

type VerifiedFirebaseUser = {
  userId: string;
  token: string;
};

// ─── Upload policy ────────────────────────────────────────────────────────────

// Maximum allowed upload size in bytes.
const MAX_UPLOAD_BYTES = 10 * 1024 * 1024; // 10 MB

// Presigned URL expiry in seconds (5 minutes is enough for the Flutter upload).
const PRESIGNED_URL_EXPIRY_SECONDS = 300;

// Allowed MIME types (exact allow-list; SVG rejected).
const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

// Allowed file extensions (explicit allow-list).
const ALLOWED_EXTENSIONS = new Set(['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif']);

// MIME ↔ extension pairs that must match.
const MIME_EXTENSIONS: Record<string, Set<string>> = {
  'image/jpeg': new Set(['jpg', 'jpeg']),
  'image/png': new Set(['png']),
  'image/webp': new Set(['webp']),
  'image/heic': new Set(['heic']),
  'image/heif': new Set(['heif']),
};

const SAFE_CIRCLE_ID = /^[A-Za-z0-9_-]{1,128}$/;

// ─── JWKS cache (module-level, reused across invocations) ────────────────────

const firebaseJwks = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);

// ─── Entry point ─────────────────────────────────────────────────────────────

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const corsHeaders = buildCorsHeaders(env);

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return errorJson('Method not allowed', 405, corsHeaders);
    }

    // ── 1. Verify Firebase ID token ─────────────────────────────────────────

    const firebaseUser = await verifyFirebaseUser(request, env);
    if (!firebaseUser) {
      return errorJson('Unauthorized', 401, corsHeaders);
    }

    // ── 2. Parse and validate request body ──────────────────────────────────

    let body: SignRequest;
    try {
      body = (await request.json()) as SignRequest;
    } catch {
      return errorJson('Invalid JSON body', 400, corsHeaders);
    }

    const validationError = validateSignRequest(body);
    if (validationError) {
      return errorJson(validationError, 400, corsHeaders);
    }

    // ── 3. Circle membership check for Circle-scoped media ──────────────────

    if (isCircleMediaType(body.type!)) {
      let isMember: boolean;
      try {
        isMember = await verifyCircleMembership({
          env,
          firebaseIdToken: firebaseUser.token,
          circleId: body.circleId!,
          userId: firebaseUser.userId,
        });
      } catch (err) {
        console.error('membership_check_failed', {
          circleId: body.circleId,
          userId: firebaseUser.userId,
          error: String(err),
        });
        return errorJson('Could not verify Circle membership', 503, corsHeaders);
      }

      if (!isMember) {
        return errorJson('Circle membership required', 403, corsHeaders);
      }
    }

    // ── 4. Build object key ──────────────────────────────────────────────────

    const extension = normalizeExtension(body.fileExtension!);
    const objectKey = buildObjectKey({
      type: body.type!,
      userId: firebaseUser.userId,
      circleId: body.circleId,
      extension,
    });

    // ── 5. Sign the R2 PUT URL ───────────────────────────────────────────────

    const aws = new AwsClient({
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
      service: 's3',
      region: 'auto',
    });

    const uploadUrl =
      `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com/` +
      `${env.R2_BUCKET_NAME}/${objectKey}` +
      `?X-Amz-Expires=${PRESIGNED_URL_EXPIRY_SECONDS}`;

    const signed = await aws.sign(uploadUrl, {
      method: 'PUT',
      headers: {
        'content-type': body.contentType!,
        'content-length': String(body.contentLength!),
      },
      aws: {
        signQuery: true,
      },
    });

    // ── 6. Return signed URL + public URL ────────────────────────────────────

    console.log('sign_request_ok', {
      type: body.type,
      userId: firebaseUser.userId,
      objectKey,
      contentLength: body.contentLength,
    });

    return okJson(
      {
        uploadUrl: signed.url,
        publicUrl: `${trimTrailingSlash(env.R2_PUBLIC_BASE_URL)}/${objectKey}`,
        objectKey,
        method: 'PUT',
        headers: {
          'content-type': body.contentType,
          'content-length': String(body.contentLength),
        },
        expiresInSeconds: PRESIGNED_URL_EXPIRY_SECONDS,
      },
      200,
      corsHeaders,
    );
  },
};

// ─── Firebase token verification ─────────────────────────────────────────────

async function verifyFirebaseUser(
  request: Request,
  env: Env,
): Promise<VerifiedFirebaseUser | null> {
  const authorization = request.headers.get('authorization') ?? '';
  const match = authorization.match(/^Bearer (.+)$/);
  if (!match) {
    return null;
  }
  const rawToken = match[1];

  try {
    const issuer = `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`;
    const verified = await jwtVerify(rawToken, firebaseJwks, {
      issuer,
      audience: env.FIREBASE_PROJECT_ID,
    });
    if (typeof verified.payload.sub !== 'string' || !verified.payload.sub) {
      return null;
    }
    return { userId: verified.payload.sub, token: rawToken };
  } catch {
    return null;
  }
}

// ─── Request validation ───────────────────────────────────────────────────────

function validateSignRequest(body: SignRequest): string | null {
  const validTypes: UploadType[] = ['avatar', 'circleCover', 'messagePhoto', 'pulsePhoto'];
  if (!body.type || !validTypes.includes(body.type)) {
    return 'Invalid upload type. Must be one of: avatar, circleCover, messagePhoto, pulsePhoto';
  }

  if (!body.contentType || !ALLOWED_MIME_TYPES.has(body.contentType)) {
    return `Only these image types are allowed: ${[...ALLOWED_MIME_TYPES].join(', ')}`;
  }

  if (!body.fileExtension || !/^\.?[a-zA-Z0-9]{2,5}$/.test(body.fileExtension)) {
    return 'Invalid file extension';
  }

  const normalizedExt = normalizeExtension(body.fileExtension);
  if (!ALLOWED_EXTENSIONS.has(normalizedExt)) {
    return `File extension not allowed. Allowed: ${[...ALLOWED_EXTENSIONS].join(', ')}`;
  }

  const allowedExtsForMime = MIME_EXTENSIONS[body.contentType];
  if (!allowedExtsForMime || !allowedExtsForMime.has(normalizedExt)) {
    return 'File extension does not match content type';
  }

  if (isCircleMediaType(body.type) && !body.circleId) {
    return 'circleId is required for Circle media';
  }

  if (body.circleId && !SAFE_CIRCLE_ID.test(body.circleId)) {
    return 'Invalid circleId';
  }

  if (
    typeof body.contentLength !== 'number' ||
    !Number.isFinite(body.contentLength) ||
    body.contentLength <= 0 ||
    body.contentLength > MAX_UPLOAD_BYTES
  ) {
    return `contentLength is required and must be between 1 and ${MAX_UPLOAD_BYTES} bytes`;
  }

  return null;
}

function isCircleMediaType(type: UploadType | undefined): boolean {
  return type === 'circleCover' || type === 'messagePhoto' || type === 'pulsePhoto';
}

// ─── Circle membership check via Firestore REST API ──────────────────────────

async function verifyCircleMembership(input: {
  env: Env;
  firebaseIdToken: string;
  circleId: string;
  userId: string;
}): Promise<boolean> {
  // Use the user's own Firebase ID token. Firestore rules enforce that a user
  // can only read their own membership document, so this is least-privilege.
  const documentPath = [
    'circles',
    encodeURIComponent(input.circleId),
    'members',
    encodeURIComponent(input.userId),
  ].join('/');

  const url =
    `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(input.env.FIREBASE_PROJECT_ID)}` +
    `/databases/(default)/documents/${documentPath}`;

  const response = await fetch(url, {
    method: 'GET',
    headers: {
      authorization: `Bearer ${input.firebaseIdToken}`,
    },
  });

  if (response.status === 200) {
    return true;
  }
  if (response.status === 403 || response.status === 404) {
    return false;
  }

  throw new Error(`Firestore membership check returned unexpected status ${response.status}`);
}

// ─── Object key builder ───────────────────────────────────────────────────────

function buildObjectKey(input: {
  type: UploadType;
  userId: string;
  circleId?: string;
  extension: string;
}): string {
  const id = crypto.randomUUID();
  switch (input.type) {
    case 'avatar':
      return `users/${input.userId}/avatars/${id}.${input.extension}`;
    case 'circleCover':
      return `circles/${input.circleId}/covers/${id}.${input.extension}`;
    case 'messagePhoto':
      return `circles/${input.circleId}/messages/${id}.${input.extension}`;
    case 'pulsePhoto':
      return `circles/${input.circleId}/pulses/${id}.${input.extension}`;
  }
}

// ─── Utilities ────────────────────────────────────────────────────────────────

function normalizeExtension(extension: string): string {
  return extension.replace(/^\./, '').toLowerCase();
}

function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, '');
}

function buildCorsHeaders(env: Env): HeadersInit {
  return {
    'access-control-allow-origin': env.ALLOWED_ORIGIN ?? '*',
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
    'access-control-max-age': '86400',
  };
}

function okJson(body: unknown, status: number, corsHeaders: HeadersInit): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  });
}

function errorJson(message: string, status: number, corsHeaders: HeadersInit): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  });
}
