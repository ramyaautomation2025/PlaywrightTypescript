# Playwright TypeScript Test Automation Project

A basic Playwright test automation project using TypeScript with API testing examples.

## Project Structure

```
├── tests/
│   └── api.test.ts          # API test file with dummy tests
├── playwright.config.ts     # Playwright configuration
├── tsconfig.json           # TypeScript configuration
├── package.json            # Project dependencies
└── README.md              # This file
```

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

This will install:
- `@playwright/test` - Playwright testing framework
- `typescript` - TypeScript compiler
- `@types/node` - Node.js type definitions

### 2. Run Tests

Run all tests:
```bash
npm test
```

Run tests in headed mode (see browser):
```bash
npm run test:headed
```

Run tests in UI mode (interactive):
```bash
npm run test:ui
```

Debug tests:
```bash
npm run test:debug
```

## Test File Details

The `tests/api.test.ts` file contains the following dummy API tests using JSONPlaceholder (a fake JSON API):

1. **GET Request** - Fetch user data
2. **POST Request** - Create a new post
3. **GET Request** - Fetch all posts by user
4. **PUT Request** - Update a post
5. **DELETE Request** - Remove a post
6. **Response Validation** - Verify API response headers

## Configuration

### playwright.config.ts
- **testDir**: `./tests` - Directory containing test files
- **reporter**: `html` - HTML report generation
- **projects**: Chromium, Firefox, and WebKit browsers
- **baseURL**: Set to `https://api.example.com` (customize as needed)

### tsconfig.json
- Target: ES2020
- Strict mode enabled
- Module resolution: bundler

## Writing New Tests

To add new API tests, create a new test file in the `tests/` directory:

```typescript
import { test, expect } from '@playwright/test';

test('your test description', async ({ request }) => {
  const response = await request.get('https://api.example.com/endpoint');
  expect(response.status()).toBe(200);
  
  const data = await response.json();
  expect(data).toHaveProperty('expectedProperty');
});
```

## Resources

- [Playwright Documentation](https://playwright.dev)
- [Playwright API Testing Guide](https://playwright.dev/docs/api-testing)
- [TypeScript Documentation](https://www.typescriptlang.org)
- [JSONPlaceholder API](https://jsonplaceholder.typicode.com)

## Notes

- The test uses JSONPlaceholder as a public API for dummy testing
- Tests are configured to run in parallel for faster execution
- HTML reports are generated in the `playwright-report/` directory after test runs
- Test results and videos are stored in the `test-results/` directory
