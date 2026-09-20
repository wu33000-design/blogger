# Firestore CMS Schema

This document is the implementation contract for Field Notes CMS.

## Collections

### `users/{uid}`

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `displayName` | string | yes | CMS display name |
| `role` | string | yes | `admin` or `editor` |
| `createdAt` | timestamp | yes | server timestamp |
| `updatedAt` | timestamp | yes | server timestamp |

The first administrator is bootstrapped manually in Firebase Console after the
Authentication user is created. There is deliberately no public sign-up path.

### `posts/{postId}`

| Field | Type | Required |
| --- | --- | --- |
| `title` | string | yes |
| `slug` | string | yes |
| `status` | string: `draft` / `published` | yes |
| `excerpt` | string | yes |
| `content` | map / structured editor document | yes |
| `html` | string | yes |
| `tagIds` | array<string> | yes |
| `authorId` | string | yes |
| `featured` | boolean | yes |
| `featureImage` | string/null | yes |
| `featureImageAlt` | string/null | yes |
| `createdAt` | timestamp | yes |
| `updatedAt` | timestamp | yes |
| `publishedAt` | timestamp/null | yes |

### `tags/{tagId}`

Fields: `name`, `slug`, `description`, `createdAt`, `updatedAt`.

## Security boundary

The browser CMS uses Firebase Authentication and the Firebase Web SDK.
Firestore rules authorize reads/writes by consulting the authenticated user's
`users/{uid}.role`. Reader-facing pages never query Firestore.

Server/build-time Firestore access will be added in Phase 4 and must use a
server credential/IAM boundary. Service-account private keys must never be
committed or emitted into the browser bundle.

## Bootstrap

1. Create/attach a Firebase project.
2. Enable Authentication and the desired sign-in provider.
3. Create the initial Authentication user in Firebase Console.
4. Create `users/{uid}` with `role: "admin"` and the required fields.
5. Deploy `firestore.rules`.
6. Configure the `PUBLIC_FIREBASE_*` build variables.

Until Firebase is configured, the public Astro site continues to use its
existing preview content fallback.
