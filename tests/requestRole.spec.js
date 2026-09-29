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

  // Nyt request-UI (ngar): /ui/d/request-center redirecter til .../ngar/request-access/for-self
  await page.goto('/ui/d/request-center');
  await page.getByTestId('ngar-search-input').fill(ROLE_NAME);
  await page.getByTestId('ngar-search-input').press('Enter');

  await expect(page.getByRole('button', { name: `View details for ${ROLE_NAME}` })).toBeVisible({ timeout: 10000 });

  await page.getByRole('button', { name: 'Select', exact: true }).click();
  await page.getByRole('button', { name: 'Continue' }).click();
  await expect(page).toHaveURL(/for-self\/cart/);

  await page.getByRole('button', { name: 'Submit Request' }).click();
  await expect(page).toHaveURL(/for-self\/success/, { timeout: 30000 });
  await expect(page.getByText('Request Submitted')).toBeVisible();
});
