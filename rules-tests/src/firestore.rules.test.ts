/**
 * Firestore Security Rules – CirclePlus
 *
 * Runs against the Firebase Emulator Suite (Firestore).
 *
 * Start the emulator before running:
 *   firebase emulators:start --only firestore
 *
 * Or run everything together:
 *   firebase emulators:exec --only firestore "cd rules-tests && npm test"
 *
 * Tests use @firebase/rules-unit-testing v3 which wraps the REST-based
 * emulator API. Each test suite gets an isolated project ID so tests
 * cannot bleed into each other.
 */

import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "fs";
import { resolve } from "path";
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  deleteField,
  collection,
  getDocs,
  writeBatch,
} from "firebase/firestore";

// ─── Load rules from the project root ────────────────────────────────────────

const RULES_PATH = resolve(__dirname, "../../firestore.rules");
const rules = readFileSync(RULES_PATH, "utf8");

// ─── Shared test fixtures ─────────────────────────────────────────────────────

const PROJECT_ID = "circleplus-rules-test";
const FIRESTORE_PORT = 8080;

// Stable UIDs used across tests.
const ALICE = "user-alice";
const BOB = "user-bob";
const CHARLIE = "user-charlie"; // never a member of any circle in most suites

const CIRCLE_ID = "circle-001";
const INVITE_CODE = "ABC123";
const PLAN_ID = "plan-001";
const MESSAGE_ID = "msg-001";
const PULSE_DATE_KEY = "20260516";

// ─── Helper: build a document path ───────────────────────────────────────────

function circlePath(circleId: string) {
  return `circles/${circleId}`;
}
function memberPath(circleId: string, userId: string) {
  return `circles/${circleId}/members/${userId}`;
}
function messagePath(circleId: string, msgId: string) {
  return `circles/${circleId}/messages/${msgId}`;
}
function pulsePath(circleId: string, pulseId: string) {
  return `circles/${circleId}/pulses/${pulseId}`;
}
function planPath(circleId: string, planId: string) {
  return `circles/${circleId}/plans/${planId}`;
}
function planResponsePath(circleId: string, planId: string, userId: string) {
  return `circles/${circleId}/plans/${planId}/responses/${userId}`;
}
function inviteCodePath(code: string) {
  return `inviteCodes/${code}`;
}
function userPath(userId: string) {
  return `users/${userId}`;
}

// ─── Suite factory ────────────────────────────────────────────────────────────

/**
 * Creates a fresh RulesTestEnvironment for a given suite, seeded with the
 * canonical CirclePlus fixture data (Alice as creator, Bob as member).
 */
async function makeEnv(suiteId: string): Promise<RulesTestEnvironment> {
  const env = await initializeTestEnvironment({
    projectId: `${PROJECT_ID}-${suiteId}`,
    firestore: {
      rules,
      host: "localhost",
      port: FIRESTORE_PORT,
    },
  });
  return env;
}

/**
 * Seeds baseline data using admin (bypasses rules):
 *   - Circle document
 *   - Alice as creator member
 *   - Bob as regular member
 *   - An invite code document
 */
async function seedBaseline(env: RulesTestEnvironment): Promise<void> {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const now = new Date();

    // Circle document
    await setDoc(doc(db, circlePath(CIRCLE_ID)), {
      id: CIRCLE_ID,
      name: "Weekend Crew",
      description: null,
      coverUrl: null,
      createdBy: ALICE,
      inviteCode: INVITE_CODE,
      memberCount: 2,
      lastMessageText: null,
      lastMessageAt: null,
      createdAt: now,
      updatedAt: now,
    });

    // Alice – creator
    await setDoc(doc(db, memberPath(CIRCLE_ID, ALICE)), {
      userId: ALICE,
      circleId: CIRCLE_ID,
      role: "creator",
      displayName: "Alice",
      photoUrl: null,
      joinedAt: now,
    });

    // Bob – regular member
    await setDoc(doc(db, memberPath(CIRCLE_ID, BOB)), {
      userId: BOB,
      circleId: CIRCLE_ID,
      role: "member",
      displayName: "Bob",
      photoUrl: null,
      joinedAt: now,
      inviteCodeUsed: INVITE_CODE,
    });

    // Invite code
    await setDoc(doc(db, inviteCodePath(INVITE_CODE)), {
      code: INVITE_CODE,
      circleId: CIRCLE_ID,
      createdBy: ALICE,
      createdAt: now,
    });

    // Users
    await setDoc(doc(db, userPath(ALICE)), {
      id: ALICE,
      email: "alice@example.com",
      displayName: "Alice",
      photoUrl: null,
    });
    await setDoc(doc(db, userPath(BOB)), {
      id: BOB,
      email: "bob@example.com",
      displayName: "Bob",
      photoUrl: null,
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. USER PROFILE RULES
// ─────────────────────────────────────────────────────────────────────────────

describe("User profile rules", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("user-profile");
    await seedBaseline(env);
  });

  afterAll(async () => {
    await env.cleanup();
  });

  test("owner can read their own profile", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertSucceeds(getDoc(doc(alice.firestore(), userPath(ALICE))));
  });

  test("user cannot read another user's profile", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertFails(getDoc(doc(bob.firestore(), userPath(ALICE))));
  });

  test("unauthenticated user cannot read any profile", async () => {
    const anon = env.unauthenticatedContext();
    await assertFails(getDoc(doc(anon.firestore(), userPath(ALICE))));
  });

  test("owner can create their own profile with required fields", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertSucceeds(
      setDoc(doc(charlie.firestore(), userPath(CHARLIE)), {
        id: CHARLIE,
        email: "charlie@example.com",
        displayName: "Charlie",
        photoUrl: null,
      })
    );
  });

  test("owner cannot create profile with wrong id", async () => {
    const alice = env.authenticatedContext(ALICE);
    // tries to write a profile document that claims to be CHARLIE
    await assertFails(
      setDoc(doc(alice.firestore(), userPath(CHARLIE)), {
        id: CHARLIE,
        email: "charlie@example.com",
        displayName: "Alice impersonating Charlie",
        photoUrl: null,
      })
    );
  });

  test("owner can update their own profile", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertSucceeds(
      updateDoc(doc(alice.firestore(), userPath(ALICE)), {
        displayName: "Alice Updated",
      })
    );
  });

  test("owner cannot change their own email via update", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertFails(
      updateDoc(doc(alice.firestore(), userPath(ALICE)), {
        email: "newemail@example.com",
      })
    );
  });

  test("user cannot delete a profile", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertFails(deleteDoc(doc(alice.firestore(), userPath(ALICE))));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. INVITE CODE RULES
// ─────────────────────────────────────────────────────────────────────────────

describe("Invite code rules", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("invite-codes");
    await seedBaseline(env);
  });

  afterAll(async () => env.cleanup());

  test("authenticated user can read a valid invite code", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertSucceeds(
      getDoc(doc(alice.firestore(), inviteCodePath(INVITE_CODE)))
    );
  });

  test("unauthenticated user cannot read invite codes", async () => {
    const anon = env.unauthenticatedContext();
    await assertFails(
      getDoc(doc(anon.firestore(), inviteCodePath(INVITE_CODE)))
    );
  });

  test("invite code listing is forbidden", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertFails(
      getDocs(collection(alice.firestore(), "inviteCodes"))
    );
  });

  test("invite code is immutable (update denied)", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertFails(
      updateDoc(doc(alice.firestore(), inviteCodePath(INVITE_CODE)), {
        circleId: "circle-999",
      })
    );
  });

  test("invite code cannot be deleted", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertFails(
      deleteDoc(doc(alice.firestore(), inviteCodePath(INVITE_CODE)))
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. CIRCLE ACCESS – NON-MEMBER DENIED
// ─────────────────────────────────────────────────────────────────────────────

describe("Circle access – non-member denied", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("circle-nonmember");
    await seedBaseline(env);
  });

  afterAll(async () => env.cleanup());

  test("non-member cannot read circle document", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDoc(doc(charlie.firestore(), circlePath(CIRCLE_ID)))
    );
  });

  test("unauthenticated user cannot read circle document", async () => {
    const anon = env.unauthenticatedContext();
    await assertFails(
      getDoc(doc(anon.firestore(), circlePath(CIRCLE_ID)))
    );
  });

  test("non-member cannot read member list", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDocs(collection(charlie.firestore(), `circles/${CIRCLE_ID}/members`))
    );
  });

  test("non-member cannot read messages", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDocs(
        collection(charlie.firestore(), `circles/${CIRCLE_ID}/messages`)
      )
    );
  });

  test("non-member cannot read pulses", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDocs(
        collection(charlie.firestore(), `circles/${CIRCLE_ID}/pulses`)
      )
    );
  });

  test("non-member cannot read plans", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDocs(collection(charlie.firestore(), `circles/${CIRCLE_ID}/plans`))
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. CIRCLE ACCESS – MEMBER ALLOWED
// ─────────────────────────────────────────────────────────────────────────────

describe("Circle access – member allowed", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("circle-member-access");
    await seedBaseline(env);
  });

  afterAll(async () => env.cleanup());

  test("creator (Alice) can read circle document", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertSucceeds(
      getDoc(doc(alice.firestore(), circlePath(CIRCLE_ID)))
    );
  });

  test("member (Bob) can read circle document", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertSucceeds(
      getDoc(doc(bob.firestore(), circlePath(CIRCLE_ID)))
    );
  });

  test("member (Bob) can read member list", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertSucceeds(
      getDocs(collection(bob.firestore(), `circles/${CIRCLE_ID}/members`))
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 5. CIRCLE CREATE
// ─────────────────────────────────────────────────────────────────────────────

describe("Circle create rules", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("circle-create");
    await seedBaseline(env);
  });

  afterAll(async () => env.cleanup());

  test("unauthenticated user cannot create a circle", async () => {
    const anon = env.unauthenticatedContext();
    const newCircleId = "new-circle-anon";
    await assertFails(
      setDoc(doc(anon.firestore(), circlePath(newCircleId)), {
        id: newCircleId,
        name: "Ghost Circle",
        createdBy: "anon",
        memberCount: 1,
      })
    );
  });

  test("authenticated user cannot create circle with memberCount != 1", async () => {
    const alice = env.authenticatedContext(ALICE);
    const newCircleId = "bad-circle-count";
    await assertFails(
      setDoc(doc(alice.firestore(), circlePath(newCircleId)), {
        id: newCircleId,
        name: "Bad Circle",
        createdBy: ALICE,
        memberCount: 5, // must be 1
      })
    );
  });

  test("user cannot create circle claiming another user as creator", async () => {
    const bob = env.authenticatedContext(BOB);
    const newCircleId = "spoofed-circle";
    await assertFails(
      setDoc(doc(bob.firestore(), circlePath(newCircleId)), {
        id: newCircleId,
        name: "Spoofed",
        createdBy: ALICE, // bob trying to impersonate alice
        memberCount: 1,
      })
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 6. CIRCLE JOIN – VALID AND INVALID
// ─────────────────────────────────────────────────────────────────────────────

describe("Circle join rules", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("circle-join");
    await seedBaseline(env);
  });

  afterAll(async () => env.cleanup());

  test("valid join: Charlie can join using the correct invite code (atomic batch)", async () => {
    // Charlie creates their own member document + bumps memberCount atomically.
    // This is exactly what the repository does in a transaction.
    const charlie = env.authenticatedContext(CHARLIE);
    const db = charlie.firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, memberPath(CIRCLE_ID, CHARLIE)), {
      userId: CHARLIE,
      circleId: CIRCLE_ID,
      role: "member",
      displayName: "Charlie",
      photoUrl: null,
      joinedAt: new Date(),
      inviteCodeUsed: INVITE_CODE,
    });
    batch.update(doc(db, circlePath(CIRCLE_ID)), {
      memberCount: 3, // baseline seed is Alice + Bob = 2
      updatedAt: new Date(),
    });
    await assertSucceeds(batch.commit());
  });

  test("join without memberCount increment is denied", async () => {
    const dave = "user-dave-nocount";
    const daveCtx = env.authenticatedContext(dave);
    await assertFails(
      setDoc(doc(daveCtx.firestore(), memberPath(CIRCLE_ID, dave)), {
        userId: dave,
        circleId: CIRCLE_ID,
        role: "member",
        displayName: "Dave",
        photoUrl: null,
        joinedAt: new Date(),
        inviteCodeUsed: INVITE_CODE,
      })
    );
  });

  test("invalid join: no invite code on member document is denied", async () => {
    const dave = "user-dave";
    const charlie = env.authenticatedContext(dave);
    const db = charlie.firestore();
    await assertFails(
      setDoc(doc(db, memberPath(CIRCLE_ID, dave)), {
        userId: dave,
        circleId: CIRCLE_ID,
        role: "member",
        displayName: "Dave",
        photoUrl: null,
        joinedAt: new Date(),
        // missing inviteCodeUsed
      })
    );
  });

  test("invalid join: wrong invite code is denied", async () => {
    const eve = "user-eve";
    const eveCtx = env.authenticatedContext(eve);
    await assertFails(
      setDoc(doc(eveCtx.firestore(), memberPath(CIRCLE_ID, eve)), {
        userId: eve,
        circleId: CIRCLE_ID,
        role: "member",
        displayName: "Eve",
        photoUrl: null,
        joinedAt: new Date(),
        inviteCodeUsed: "XXXXXX", // invalid code
      })
    );
  });

  test("invalid join: user cannot join as creator", async () => {
    const frank = "user-frank";
    const frankCtx = env.authenticatedContext(frank);
    await assertFails(
      setDoc(doc(frankCtx.firestore(), memberPath(CIRCLE_ID, frank)), {
        userId: frank,
        circleId: CIRCLE_ID,
        role: "creator", // not allowed for a join
        displayName: "Frank",
        photoUrl: null,
        joinedAt: new Date(),
        inviteCodeUsed: INVITE_CODE,
      })
    );
  });

  test("member cannot write another user's member document", async () => {
    const alice = env.authenticatedContext(ALICE);
    const db = alice.firestore();
    // Alice tries to add CHARLIE as a member on Charlie's behalf
    await assertFails(
      setDoc(doc(db, memberPath(CIRCLE_ID, CHARLIE)), {
        userId: CHARLIE,
        circleId: CIRCLE_ID,
        role: "member",
        displayName: "Charlie (by Alice)",
        photoUrl: null,
        joinedAt: new Date(),
        inviteCodeUsed: INVITE_CODE,
      })
    );
  });

  test("member update is forbidden (immutable membership)", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertFails(
      updateDoc(doc(bob.firestore(), memberPath(CIRCLE_ID, BOB)), {
        role: "creator",
      })
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 7. MESSAGES – SEND, READ, SOFT-DELETE
// ─────────────────────────────────────────────────────────────────────────────

describe("Message rules", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("messages");
    await seedBaseline(env);
    // seed one message from Alice
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), messagePath(CIRCLE_ID, MESSAGE_ID)), {
        id: MESSAGE_ID,
        circleId: CIRCLE_ID,
        senderId: ALICE,
        senderName: "Alice",
        senderPhotoUrl: null,
        type: "text",
        text: "Hello",
        mediaUrl: null,
        createdAt: new Date(),
        updatedAt: null,
        deletedAt: null,
      });
    });
  });

  afterAll(async () => env.cleanup());

  test("member (Bob) can read messages", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertSucceeds(
      getDocs(
        collection(bob.firestore(), `circles/${CIRCLE_ID}/messages`)
      )
    );
  });

  test("non-member (Charlie) cannot read messages", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDocs(
        collection(charlie.firestore(), `circles/${CIRCLE_ID}/messages`)
      )
    );
  });

  test("member (Bob) can send a text message", async () => {
    const bob = env.authenticatedContext(BOB);
    const newMsgId = "msg-bob-001";
    await assertSucceeds(
      setDoc(doc(bob.firestore(), messagePath(CIRCLE_ID, newMsgId)), {
        id: newMsgId,
        circleId: CIRCLE_ID,
        senderId: BOB,
        senderName: "Bob",
        senderPhotoUrl: null,
        type: "text",
        text: "Hey there!",
        mediaUrl: null,
        createdAt: new Date(),
        updatedAt: null,
      })
    );
  });

  test("member cannot send empty text message", async () => {
    const bob = env.authenticatedContext(BOB);
    const newMsgId = "msg-empty";
    await assertFails(
      setDoc(doc(bob.firestore(), messagePath(CIRCLE_ID, newMsgId)), {
        id: newMsgId,
        circleId: CIRCLE_ID,
        senderId: BOB,
        senderName: "Bob",
        senderPhotoUrl: null,
        type: "text",
        text: "", // empty
        mediaUrl: null,
        createdAt: new Date(),
        updatedAt: null,
      })
    );
  });

  test("member cannot spoof another user's senderId", async () => {
    const bob = env.authenticatedContext(BOB);
    const newMsgId = "msg-spoofed";
    await assertFails(
      setDoc(doc(bob.firestore(), messagePath(CIRCLE_ID, newMsgId)), {
        id: newMsgId,
        circleId: CIRCLE_ID,
        senderId: ALICE, // bob claims to be alice
        senderName: "Alice",
        senderPhotoUrl: null,
        type: "text",
        text: "I am Alice",
        mediaUrl: null,
        createdAt: new Date(),
        updatedAt: null,
      })
    );
  });

  test("message type 'deleted' is not allowed on create", async () => {
    const bob = env.authenticatedContext(BOB);
    const newMsgId = "msg-pre-deleted";
    await assertFails(
      setDoc(doc(bob.firestore(), messagePath(CIRCLE_ID, newMsgId)), {
        id: newMsgId,
        circleId: CIRCLE_ID,
        senderId: BOB,
        senderName: "Bob",
        type: "deleted", // not allowed on create
        createdAt: new Date(),
        updatedAt: null,
      })
    );
  });

  test("sender can soft-delete their own message", async () => {
    const alice = env.authenticatedContext(ALICE);
    // Client path: type → deleted and text/mediaUrl keys removed (not null).
    await assertSucceeds(
      updateDoc(doc(alice.firestore(), messagePath(CIRCLE_ID, MESSAGE_ID)), {
        type: "deleted",
        text: deleteField(),
        mediaUrl: deleteField(),
        deletedAt: new Date(),
      })
    );
  });

  test("soft-delete with null text/mediaUrl is denied", async () => {
    const alice = env.authenticatedContext(ALICE);
    const msgId = "msg-null-soft-delete";
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), messagePath(CIRCLE_ID, msgId)), {
        id: msgId,
        circleId: CIRCLE_ID,
        senderId: ALICE,
        senderName: "Alice",
        senderPhotoUrl: null,
        type: "text",
        text: "Hello",
        mediaUrl: null,
        createdAt: new Date(),
        updatedAt: null,
        deletedAt: null,
      });
    });
    await assertFails(
      updateDoc(doc(alice.firestore(), messagePath(CIRCLE_ID, msgId)), {
        type: "deleted",
        text: null,
        mediaUrl: null,
        deletedAt: new Date(),
      })
    );
  });

  test("non-sender cannot soft-delete another's message", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertFails(
      updateDoc(doc(bob.firestore(), messagePath(CIRCLE_ID, MESSAGE_ID)), {
        type: "deleted",
        text: deleteField(),
        mediaUrl: deleteField(),
        deletedAt: new Date(),
      })
    );
  });

  test("messages cannot be hard-deleted", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertFails(
      deleteDoc(doc(alice.firestore(), messagePath(CIRCLE_ID, MESSAGE_ID)))
    );
  });

  test("non-member cannot send a message", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    const newMsgId = "msg-charlie-intruder";
    await assertFails(
      setDoc(doc(charlie.firestore(), messagePath(CIRCLE_ID, newMsgId)), {
        id: newMsgId,
        circleId: CIRCLE_ID,
        senderId: CHARLIE,
        senderName: "Charlie",
        senderPhotoUrl: null,
        type: "text",
        text: "Intruder!",
        mediaUrl: null,
        createdAt: new Date(),
        updatedAt: null,
      })
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 8. PULSES – WRITE AS SELF ONLY
// ─────────────────────────────────────────────────────────────────────────────

describe("Pulse rules", () => {
  let env: RulesTestEnvironment;

  const alicePulseId = `${PULSE_DATE_KEY}_${ALICE}`;
  const bobPulseId = `${PULSE_DATE_KEY}_${BOB}`;

  beforeAll(async () => {
    env = await makeEnv("pulses");
    await seedBaseline(env);
    await env.withSecurityRulesDisabled(async (ctx) => {
      // Seed an existing Alice pulse
      await setDoc(
        doc(ctx.firestore(), pulsePath(CIRCLE_ID, alicePulseId)),
        {
          id: alicePulseId,
          circleId: CIRCLE_ID,
          userId: ALICE,
          userName: "Alice",
          userPhotoUrl: null,
          photoUrl: "https://r2.example.com/alice-pulse.png",
          caption: "Good morning!",
          mood: "happy",
          dateKey: PULSE_DATE_KEY,
          createdAt: new Date(),
          updatedAt: new Date(),
        }
      );
    });
  });

  afterAll(async () => env.cleanup());

  test("member can read pulses", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertSucceeds(
      getDocs(collection(bob.firestore(), `circles/${CIRCLE_ID}/pulses`))
    );
  });

  test("non-member cannot read pulses", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDocs(collection(charlie.firestore(), `circles/${CIRCLE_ID}/pulses`))
    );
  });

  test("member (Bob) can create their own pulse with correct id format", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertSucceeds(
      setDoc(doc(bob.firestore(), pulsePath(CIRCLE_ID, bobPulseId)), {
        id: bobPulseId,
        circleId: CIRCLE_ID,
        userId: BOB,
        userName: "Bob",
        userPhotoUrl: null,
        photoUrl: "https://r2.example.com/bob-pulse.png",
        caption: "My day!",
        mood: "calm",
        dateKey: PULSE_DATE_KEY,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("member cannot write a pulse for another user (id mismatch)", async () => {
    const bob = env.authenticatedContext(BOB);
    // Bob tries to write a pulse with Alice's id format
    await assertFails(
      setDoc(doc(bob.firestore(), pulsePath(CIRCLE_ID, alicePulseId)), {
        id: alicePulseId,
        circleId: CIRCLE_ID,
        userId: BOB, // Bob's uid, but pulseId belongs to Alice
        userName: "Bob",
        userPhotoUrl: null,
        photoUrl: "https://r2.example.com/bad-pulse.png",
        caption: null,
        mood: null,
        dateKey: PULSE_DATE_KEY,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("member cannot create pulse without a photoUrl", async () => {
    const bob = env.authenticatedContext(BOB);
    const noPictureId = `${PULSE_DATE_KEY}_${BOB}`;
    await assertFails(
      setDoc(doc(bob.firestore(), pulsePath(CIRCLE_ID, noPictureId)), {
        id: noPictureId,
        circleId: CIRCLE_ID,
        userId: BOB,
        userName: "Bob",
        userPhotoUrl: null,
        photoUrl: "", // empty – must be non-empty string
        caption: null,
        mood: null,
        dateKey: PULSE_DATE_KEY,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("member can delete their own pulse", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertSucceeds(
      deleteDoc(doc(alice.firestore(), pulsePath(CIRCLE_ID, alicePulseId)))
    );
  });

  test("member cannot delete another user's pulse", async () => {
    // Bob tries to delete Alice's pulse (after we re-seed it)
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), pulsePath(CIRCLE_ID, alicePulseId)),
        {
          id: alicePulseId,
          circleId: CIRCLE_ID,
          userId: ALICE,
          userName: "Alice",
          userPhotoUrl: null,
          photoUrl: "https://r2.example.com/alice-pulse.png",
          caption: "Re-seeded",
          mood: null,
          dateKey: PULSE_DATE_KEY,
          createdAt: new Date(),
          updatedAt: new Date(),
        }
      );
    });
    const bob = env.authenticatedContext(BOB);
    await assertFails(
      deleteDoc(doc(bob.firestore(), pulsePath(CIRCLE_ID, alicePulseId)))
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 9. PLANS – CREATE, COUNT UPDATE, EDIT, CANCEL
// ─────────────────────────────────────────────────────────────────────────────

describe("Plan rules", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("plans");
    await seedBaseline(env);
    // Seed a plan created by Alice
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), planPath(CIRCLE_ID, PLAN_ID)), {
        id: PLAN_ID,
        circleId: CIRCLE_ID,
        createdBy: ALICE,
        createdByName: "Alice",
        title: "Coffee meetup",
        description: null,
        location: "Cafe Latte",
        startsAt: new Date(),
        status: "active",
        inCount: 0,
        maybeCount: 0,
        cantCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });
  });

  afterAll(async () => env.cleanup());

  test("member can read plans", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertSucceeds(
      getDocs(collection(bob.firestore(), `circles/${CIRCLE_ID}/plans`))
    );
  });

  test("non-member cannot read plans", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDocs(collection(charlie.firestore(), `circles/${CIRCLE_ID}/plans`))
    );
  });

  test("member can create a plan with zeroed counts and active status", async () => {
    const bob = env.authenticatedContext(BOB);
    const newPlanId = "plan-bob-001";
    await assertSucceeds(
      setDoc(doc(bob.firestore(), planPath(CIRCLE_ID, newPlanId)), {
        id: newPlanId,
        circleId: CIRCLE_ID,
        createdBy: BOB,
        createdByName: "Bob",
        title: "Bowling night",
        description: null,
        location: null,
        startsAt: new Date(),
        status: "active",
        inCount: 0,
        maybeCount: 0,
        cantCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("member cannot create plan with pre-inflated counts", async () => {
    const bob = env.authenticatedContext(BOB);
    const badPlanId = "plan-bad-counts";
    await assertFails(
      setDoc(doc(bob.firestore(), planPath(CIRCLE_ID, badPlanId)), {
        id: badPlanId,
        circleId: CIRCLE_ID,
        createdBy: BOB,
        createdByName: "Bob",
        title: "Rigged plan",
        description: null,
        location: null,
        startsAt: new Date(),
        status: "active",
        inCount: 99, // must be 0
        maybeCount: 0,
        cantCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("member cannot create plan with cancelled status", async () => {
    const bob = env.authenticatedContext(BOB);
    const badStatusId = "plan-bad-status";
    await assertFails(
      setDoc(doc(bob.firestore(), planPath(CIRCLE_ID, badStatusId)), {
        id: badStatusId,
        circleId: CIRCLE_ID,
        createdBy: BOB,
        createdByName: "Bob",
        title: "Pre-cancelled",
        description: null,
        location: null,
        startsAt: new Date(),
        status: "cancelled", // must be 'active'
        inCount: 0,
        maybeCount: 0,
        cantCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("non-member cannot create a plan", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    const intruderPlanId = "plan-intruder";
    await assertFails(
      setDoc(doc(charlie.firestore(), planPath(CIRCLE_ID, intruderPlanId)), {
        id: intruderPlanId,
        circleId: CIRCLE_ID,
        createdBy: CHARLIE,
        createdByName: "Charlie",
        title: "Intruder plan",
        description: null,
        location: null,
        startsAt: new Date(),
        status: "active",
        inCount: 0,
        maybeCount: 0,
        cantCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("creator (Alice) can cancel the plan", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertSucceeds(
      updateDoc(doc(alice.firestore(), planPath(CIRCLE_ID, PLAN_ID)), {
        status: "cancelled",
        updatedAt: new Date(),
      })
    );
  });

  test("non-creator (Bob) cannot cancel the plan", async () => {
    // Re-seed plan as active (Alice cancelled it in previous test)
    await env.withSecurityRulesDisabled(async (ctx) => {
      await updateDoc(doc(ctx.firestore(), planPath(CIRCLE_ID, PLAN_ID)), {
        status: "active",
        updatedAt: new Date(),
      });
    });
    const bob = env.authenticatedContext(BOB);
    await assertFails(
      updateDoc(doc(bob.firestore(), planPath(CIRCLE_ID, PLAN_ID)), {
        status: "cancelled",
        updatedAt: new Date(),
      })
    );
  });

  test("creator (Alice) can edit plan content fields", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertSucceeds(
      updateDoc(doc(alice.firestore(), planPath(CIRCLE_ID, PLAN_ID)), {
        title: "Coffee meetup – updated",
        description: "Changed location",
        location: "New Cafe",
        startsAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("non-creator (Bob) cannot edit plan content fields", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertFails(
      updateDoc(doc(bob.firestore(), planPath(CIRCLE_ID, PLAN_ID)), {
        title: "Bob hijacks the title",
        updatedAt: new Date(),
      })
    );
  });

  test("plans cannot be deleted", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertFails(
      deleteDoc(doc(alice.firestore(), planPath(CIRCLE_ID, PLAN_ID)))
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 10. PLAN RESPONSES + ATOMIC COUNT PROTECTION
// ─────────────────────────────────────────────────────────────────────────────

describe("Plan response and atomic count rules", () => {
  let env: RulesTestEnvironment;
  const RESP_PLAN_ID = "plan-resp-001";

  beforeAll(async () => {
    env = await makeEnv("plan-responses");
    await seedBaseline(env);
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), planPath(CIRCLE_ID, RESP_PLAN_ID)), {
        id: RESP_PLAN_ID,
        circleId: CIRCLE_ID,
        createdBy: ALICE,
        createdByName: "Alice",
        title: "Park picnic",
        description: null,
        location: "City Park",
        startsAt: new Date(),
        status: "active",
        inCount: 0,
        maybeCount: 0,
        cantCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });
  });

  afterAll(async () => env.cleanup());

  test("member can read plan responses", async () => {
    const alice = env.authenticatedContext(ALICE);
    await assertSucceeds(
      getDocs(
        collection(
          alice.firestore(),
          `circles/${CIRCLE_ID}/plans/${RESP_PLAN_ID}/responses`
        )
      )
    );
  });

  test("non-member cannot read plan responses", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      getDocs(
        collection(
          charlie.firestore(),
          `circles/${CIRCLE_ID}/plans/${RESP_PLAN_ID}/responses`
        )
      )
    );
  });

  test("atomic response + count update is allowed (Bob responds 'in')", async () => {
    // The repository uses a transaction to write the response doc AND update
    // the plan counts simultaneously. The rules check getAfter() on the plan.
    // We simulate this by using a batch write in the test.
    const bob = env.authenticatedContext(BOB);
    const db = bob.firestore();
    const { writeBatch, serverTimestamp } = await import("firebase/firestore");
    const batch = writeBatch(db);

    // Response document
    batch.set(
      doc(db, planResponsePath(CIRCLE_ID, RESP_PLAN_ID, BOB)),
      {
        userId: BOB,
        userName: "Bob",
        userPhotoUrl: null,
        response: "in",
        comment: null,
        updatedAt: serverTimestamp(),
      }
    );

    // Plan count update (+1 inCount)
    batch.update(doc(db, planPath(CIRCLE_ID, RESP_PLAN_ID)), {
      inCount: 1,
      maybeCount: 0,
      cantCount: 0,
      updatedAt: serverTimestamp(),
    });

    await assertSucceeds(batch.commit());
  });

  test("member cannot inflate plan count without a matching response", async () => {
    // Bob tries to directly update counts without a corresponding response write.
    const bob = env.authenticatedContext(BOB);
    await assertFails(
      updateDoc(doc(bob.firestore(), planPath(CIRCLE_ID, RESP_PLAN_ID)), {
        inCount: 999, // no matching getAfter() response document
        updatedAt: new Date(),
      })
    );
  });

  test("member cannot submit response for another user", async () => {
    const bob = env.authenticatedContext(BOB);
    const db = bob.firestore();
    // Bob tries to write a response under Alice's userId
    await assertFails(
      setDoc(doc(db, planResponsePath(CIRCLE_ID, RESP_PLAN_ID, ALICE)), {
        userId: ALICE,
        userName: "Alice",
        userPhotoUrl: null,
        response: "in",
        comment: null,
        updatedAt: new Date(),
      })
    );
  });

  test("response with invalid value is denied", async () => {
    const alice = env.authenticatedContext(ALICE);
    const db = alice.firestore();
    const { writeBatch, serverTimestamp } = await import("firebase/firestore");
    const batch = writeBatch(db);

    batch.set(doc(db, planResponsePath(CIRCLE_ID, RESP_PLAN_ID, ALICE)), {
      userId: ALICE,
      userName: "Alice",
      userPhotoUrl: null,
      response: "yes-please", // invalid – must be 'in', 'maybe', or 'cant'
      comment: null,
      updatedAt: serverTimestamp(),
    });
    // Counts are technically correct but response value is invalid
    batch.update(doc(db, planPath(CIRCLE_ID, RESP_PLAN_ID)), {
      inCount: 2,
      maybeCount: 0,
      cantCount: 0,
      updatedAt: serverTimestamp(),
    });

    await assertFails(batch.commit());
  });

  test("plan response cannot be deleted", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertFails(
      deleteDoc(
        doc(bob.firestore(), planResponsePath(CIRCLE_ID, RESP_PLAN_ID, BOB))
      )
    );
  });

  test("responses on cancelled plans are denied", async () => {
    const cancelledPlanId = "plan-cancelled-resp";
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), planPath(CIRCLE_ID, cancelledPlanId)), {
        id: cancelledPlanId,
        circleId: CIRCLE_ID,
        createdBy: ALICE,
        createdByName: "Alice",
        title: "Cancelled meetup",
        description: null,
        location: null,
        startsAt: new Date(),
        status: "cancelled",
        inCount: 0,
        maybeCount: 0,
        cantCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    const bob = env.authenticatedContext(BOB);
    const db = bob.firestore();
    const batch = writeBatch(db);
    batch.set(doc(db, planResponsePath(CIRCLE_ID, cancelledPlanId, BOB)), {
      userId: BOB,
      userName: "Bob",
      userPhotoUrl: null,
      response: "in",
      comment: null,
      updatedAt: new Date(),
    });
    batch.update(doc(db, planPath(CIRCLE_ID, cancelledPlanId)), {
      inCount: 1,
      maybeCount: 0,
      cantCount: 0,
      updatedAt: new Date(),
    });
    await assertFails(batch.commit());
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 11. CIRCLE UPDATE – LAST MESSAGE FIELDS
// ─────────────────────────────────────────────────────────────────────────────

describe("Circle update rules", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("circle-update");
    await seedBaseline(env);
  });

  afterAll(async () => env.cleanup());

  test("member can update lastMessage preview fields", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertSucceeds(
      updateDoc(doc(bob.firestore(), circlePath(CIRCLE_ID)), {
        lastMessageText: "Hey everyone!",
        lastMessageAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });

  test("member cannot update arbitrary fields on circle document", async () => {
    const bob = env.authenticatedContext(BOB);
    await assertFails(
      updateDoc(doc(bob.firestore(), circlePath(CIRCLE_ID)), {
        name: "Bob hijacks the name",
        updatedAt: new Date(),
      })
    );
  });

  test("non-member cannot update circle document", async () => {
    const charlie = env.authenticatedContext(CHARLIE);
    await assertFails(
      updateDoc(doc(charlie.firestore(), circlePath(CIRCLE_ID)), {
        lastMessageText: "Intruder!",
        lastMessageAt: new Date(),
        updatedAt: new Date(),
      })
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 12. COLLECTION-GROUP MEMBERS QUERY
// ─────────────────────────────────────────────────────────────────────────────

describe("Collection-group members query", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("collectiongroup-members");
    await seedBaseline(env);
  });

  afterAll(async () => env.cleanup());

  test("user can read their own member documents via collectionGroup", async () => {
    const bob = env.authenticatedContext(BOB);
    // This simulates the home screen query: collectionGroup('members').where('userId', '==', userId)
    const { query, where, collectionGroup: cg } = await import("firebase/firestore");
    await assertSucceeds(
      getDocs(
        query(
          cg(bob.firestore(), "members"),
          where("userId", "==", BOB)
        )
      )
    );
  });

  test("user cannot read another user's member documents via collectionGroup", async () => {
    const bob = env.authenticatedContext(BOB);
    const { query, where, collectionGroup: cg } = await import("firebase/firestore");
    await assertFails(
      getDocs(
        query(
          cg(bob.firestore(), "members"),
          where("userId", "==", ALICE) // querying for Alice's memberships
        )
      )
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 13. CIRCLE DELETE + ORPHAN GUARDS
// ─────────────────────────────────────────────────────────────────────────────

describe("Circle delete and orphan guards", () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await makeEnv("circle-delete");
  });

  afterAll(async () => env.cleanup());

  test("last-member creator can delete Circle + own membership atomically", async () => {
    const soloCircleId = "circle-solo-delete";
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, circlePath(soloCircleId)), {
        id: soloCircleId,
        name: "Solo Circle",
        description: null,
        coverUrl: null,
        createdBy: ALICE,
        inviteCode: "SOLO01",
        memberCount: 1,
        lastMessageText: null,
        lastMessageAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      await setDoc(doc(db, memberPath(soloCircleId, ALICE)), {
        userId: ALICE,
        circleId: soloCircleId,
        role: "creator",
        displayName: "Alice",
        photoUrl: null,
        joinedAt: new Date(),
        inviteCodeUsed: null,
      });
      await setDoc(doc(db, messagePath(soloCircleId, "orphan-msg")), {
        id: "orphan-msg",
        circleId: soloCircleId,
        senderId: ALICE,
        senderName: "Alice",
        senderPhotoUrl: null,
        type: "text",
        text: "left behind",
        mediaUrl: null,
        createdAt: new Date(),
        updatedAt: null,
        deletedAt: null,
      });
    });

    const alice = env.authenticatedContext(ALICE);
    const db = alice.firestore();
    const batch = writeBatch(db);
    batch.delete(doc(db, memberPath(soloCircleId, ALICE)));
    batch.delete(doc(db, circlePath(soloCircleId)));
    await assertSucceeds(batch.commit());
  });

  test("join is denied when Circle parent document is missing", async () => {
    const ghostCircleId = "circle-ghost";
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), inviteCodePath("GHOST1")), {
        code: "GHOST1",
        circleId: ghostCircleId,
        createdBy: ALICE,
        createdAt: new Date(),
      });
    });

    const bob = env.authenticatedContext(BOB);
    await assertFails(
      setDoc(doc(bob.firestore(), memberPath(ghostCircleId, BOB)), {
        userId: BOB,
        circleId: ghostCircleId,
        role: "member",
        displayName: "Bob",
        photoUrl: null,
        joinedAt: new Date(),
        inviteCodeUsed: "GHOST1",
      })
    );
  });

  test("orphaned messages are unreadable after Circle parent is deleted", async () => {
    const orphanCircleId = "circle-orphan-msg";
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      // Seed orphaned message + member without a Circle parent.
      await setDoc(doc(db, memberPath(orphanCircleId, BOB)), {
        userId: BOB,
        circleId: orphanCircleId,
        role: "member",
        displayName: "Bob",
        photoUrl: null,
        joinedAt: new Date(),
        inviteCodeUsed: "ORPH01",
      });
      await setDoc(doc(db, messagePath(orphanCircleId, "msg-orphan")), {
        id: "msg-orphan",
        circleId: orphanCircleId,
        senderId: BOB,
        senderName: "Bob",
        senderPhotoUrl: null,
        type: "text",
        text: "secret",
        mediaUrl: null,
        createdAt: new Date(),
        updatedAt: null,
        deletedAt: null,
      });
    });

    const bob = env.authenticatedContext(BOB);
    await assertFails(
      getDoc(doc(bob.firestore(), messagePath(orphanCircleId, "msg-orphan")))
    );
  });
});
