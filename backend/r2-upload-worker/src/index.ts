import { AwsClient } from 'aws4fetch';
import { createRemoteJWKSet, jwtVerify } from 'jose';

type Env = {
  FIREBASE_PROJECT_ID: string;
  R2_ACCOUNT_ID: string;
  R2_BUCKET_NAME: string;
  R2_PUBLIC_BASE_URL: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  ALLOWED_ORIGIN?: string;
};

type UploadType = 'avatar' | 'circleCover' | 'messagePhoto' | 'pulsePhoto';

type SignRequest = {
  type?: UploadType;
  contentType?: string;
  fileExtension?: string;
  circleId?: string;
};

type VerifiedFirebaseUser = {
  userId: string;
  token: string;
};

const firebaseJwks = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'),
);

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const corsHeaders = buildCorsHeaders(env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (request.method !== 'POST') {
      return json({ error: 'Method not allowed' }, 405, corsHeaders);
    }

    const firebaseUser = await verifyFirebaseUser(request, env);
    if (!firebaseUser) {
      return json({ error: 'Unauthorized' }, 401, corsHeaders);
    }

    let body: SignRequest;
    try {
      body = (await request.json()) as SignRequest;
    } catch {
      return json({ error: 'Invalid JSON body' }, 400, corsHeaders);
    }

    const validationError = validateSignRequest(body);
    if (validationError) {
      return json({ error: validationError }, 400, corsHeaders);
    }

    if (isCircleMediaType(body.type!)) {
      try {
        const isMember = await verifyCircleMembership({
          env,
          firebaseIdToken: firebaseUser.token,
          circleId: body.circleId!,
          userId: firebaseUser.userId,
        });
        if (!isMember) {
          return json({ error: 'Circle membership required' }, 403, corsHeaders);
        }
      } catch {
        return json({ error: 'Could not verify Circle membership' }, 503, corsHeaders);
      }
    }

    const extension = normalizeExtension(body.fileExtension!);
    const objectKey = buildObjectKey({
      type: body.type!,
      userId: firebaseUser.userId,
      circleId: body.circleId,
      extension,
    });

    const aws = new AwsClient({
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
      service: 's3',
      region: 'auto',
    });

    const uploadUrl = `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${env.R2_BUCKET_NAME}/${objectKey}`;
    const signed = await aws.sign(uploadUrl, {
      method: 'PUT',
      headers: {
        'content-type': body.contentType!,
      },
      aws: { signQuery: true },
    });

    return json(
      {
        uploadUrl: signed.url,
        publicUrl: `${trimTrailingSlash(env.R2_PUBLIC_BASE_URL)}/${objectKey}`,
        objectKey,
        method: 'PUT',
        headers: {
          'content-type': body.contentType,
        },
      },
      200,
      corsHeaders,
    );
  },
};

async function verifyFirebaseUser(
  request: Request,
  env: Env,
): Promise<VerifiedFirebaseUser | null> {
  const authorization = request.headers.get('authorization') ?? '';
  const match = authorization.match(/^Bearer (.+)$/);
  if (!match) {
    return null;
  }

  try {
    const issuer = `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`;
    const verified = await jwtVerify(match[1], firebaseJwks, {
      issuer,
      audience: env.FIREBASE_PROJECT_ID,
    });
    if (typeof verified.payload.sub !== 'string') {
      return null;
    }
    return { userId: verified.payload.sub, token: match[1] };
  } catch {
    return null;
  }
}

function validateSignRequest(body: SignRequest): string | null {
  if (!body.type || !['avatar', 'circleCover', 'messagePhoto', 'pulsePhoto'].includes(body.type)) {
    return 'Invalid upload type';
  }
  if (!body.contentType?.startsWith('image/')) {
    return 'Only image uploads are allowed';
  }
  if (!body.fileExtension || !/^[a-z0-9]{2,5}$/i.test(body.fileExtension)) {
    return 'Invalid file extension';
  }
  if (
    isCircleMediaType(body.type) &&
    !body.circleId
  ) {
    return 'circleId is required for Circle media';
  }
  if (body.circleId && body.circleId.includes('/')) {
    return 'Invalid Circle ID';
  }
  return null;
}

function isCircleMediaType(type: UploadType | undefined): boolean {
  return type === 'circleCover' || type === 'messagePhoto' || type === 'pulsePhoto';
}

async function verifyCircleMembership(input: {
  env: Env;
  firebaseIdToken: string;
  circleId: string;
  userId: string;
}): Promise<boolean> {
  const documentPath = [
    'circles',
    encodeURIComponent(input.circleId),
    'members',
    encodeURIComponent(input.userId),
  ].join('/');
  const url = `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(
    input.env.FIREBASE_PROJECT_ID,
  )}/databases/(default)/documents/${documentPath}`;

  const response = await fetch(url, {
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

  throw new Error(`Firestore membership check failed with ${response.status}`);
}

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

function normalizeExtension(extension: string): string {
  return extension.replace(/^\./, '').toLowerCase();
}

function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, '');
}

function buildCorsHeaders(env: Env): HeadersInit {
  return {
    'access-control-allow-origin': env.ALLOWED_ORIGIN || '*',
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'authorization, content-type',
    'content-type': 'application/json',
  };
}

function json(
  body: unknown,
  status: number,
  headers: HeadersInit,
): Response {
  return new Response(JSON.stringify(body), { status, headers });
}
