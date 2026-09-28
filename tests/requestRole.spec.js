const { test, expect } = require('@playwright/test');

// Kundespecifik værdi - en rolle der reelt findes i kunde-a's access request-katalog.
const ROLE_NAME = 'TestRole';

test('anmod om adgang til en rolle via access request-kataloget', async ({ page }) => {
  test.setTimeout(60000);
  test.skip(
    !process.env.ISC_USERNAME || !process.env.ISC_PASSWORD,
    'ISC_USERNAME/ISC_PASSWORD er ikke sat - springer request-test over'
  );

  await page.goto('/');
  await page.fill('#username', process.env.ISC_USERNAME);
  await page.fill('#password', process.env.ISC_PASSWORD);
  await page.click('button[type="submit"]');
  await expect(page.locator('#password')).toBeHidden({ timeout: 15000 });

  await page.goto('/ui/d/request-center');
  await page.getByRole('button', { name: 'Request for Myself' }).click();

  await page.getByTestId('search-bar-input').fill(ROLE_NAME);
  await page.getByTestId('search-bar-input').press('Enter');
  await expect(page.getByLabel(`Select ${ROLE_NAME} for request`)).toBeVisible({ timeout: 10000 });

  await page.getByLabel(`Select ${ROLE_NAME} for request`).click();
  await page.getByLabel('Review and Submit 1 request').click();
  await page.getByTestId('request-review-submit-request-button').click();

  await expect(page.getByText('Your request was submitted.')).toBeVisible({ timeout: 30000 });
});
