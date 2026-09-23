const { test, expect } = require('@playwright/test');

// Kundespecifik testværdi - en rolle der reelt findes i kunde-a's access
// request-katalog (verificeret mod den faktiske sandbox-tenant). Hardcoded
// her (og ikke i common/), fordi det er netop den slags kundeafhængige værdi
// denne opdeling findes for.
const ROLE_NAME = 'Accounts Receivable Analyst';

test('anmod om adgang til en rolle via access request-kataloget', async ({ page }) => {
  test.skip(
    !process.env.ISC_USERNAME || !process.env.ISC_PASSWORD,
    'ISC_USERNAME/ISC_PASSWORD er ikke sat - springer request-test over'
  );

  // Login (samme mønster som isc-test-common/tests/login.spec.js)
  await page.goto('/');
  await page.fill('#username', process.env.ISC_USERNAME);
  await page.fill('#password', process.env.ISC_PASSWORD);
  await page.click('button[type="submit"]');
  await expect(page.locator('#password')).toBeHidden({ timeout: 15000 });

  // Access request-flowet ligger under "Request Center" -> "Request for Myself".
  await page.goto('/ui/d/request-center');
  await page.getByRole('button', { name: 'Request for Myself' }).click();

  // 1. Søg efter rollen i access request-kataloget
  await page.getByPlaceholder(/Search Access Items/i).fill(ROLE_NAME);
  const roleCard = page.getByText(ROLE_NAME, { exact: false }).first();
  await expect(roleCard).toBeVisible({ timeout: 10000 });

  // 2. Tilføj til cart og indsend anmodningen
  //
  // KENDT BEGRÆNSNING (ligesom MFA-forbeholdet på login.spec.js): "Select" på
  // kortet åbner et "Who Are You Requesting For?"-panel med identiteten
  // forudfyldt som chip, men "Select These Identities"-knappen forblev
  // aria-disabled i manuel afprøvning mod sandbox-tenanten, uanset hvilket
  // access item der blev valgt. Det virker til at være en tilstand i selve
  // ISC-UI'et (ikke en forkert selector), som kræver at blive undersøgt
  // interaktivt, fx med `npx playwright codegen <TENANT_URL>` mens man er
  // logget ind. Linjerne herunder er derfor uverificerede og skal rettes til,
  // når flowet er afklaret.
  await page
    .locator('button', { hasText: 'Select' })
    .first()
    .click();
  await page.getByRole('button', { name: 'Select These Identities' }).click();
  await page.getByRole('button', { name: /Review Request/i }).click();
  await page.getByRole('button', { name: /submit request/i }).click();

  await expect(page.getByText(/request submitted|anmodning.*sendt/i)).toBeVisible({ timeout: 10000 });
});
