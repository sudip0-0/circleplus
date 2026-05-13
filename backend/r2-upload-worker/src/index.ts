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

    const userId = await verifyFirebaseUser(request, env);
    if (!userId) {
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

    const extension = normalizeExtension(body.fileExtension!);
    const objectKey = buildObjectKey({
      type: body.type!,
      userId,
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
): Promise<string | null> {
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
    return verified.payload.sub ?? null;
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
    ['circleCover', 'messagePhoto', 'pulsePhoto'].includes(body.type) &&
    !body.circleId
  ) {
    return 'circleId is required for Circle media';
  }
  return null;
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
