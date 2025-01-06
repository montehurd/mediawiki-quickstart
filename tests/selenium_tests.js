
'use strict';

describe('Quickstart Selenium', () => {
    it('should show Version heading', async () => {
        await browser.url('http://localhost:8080/wiki/Special:Version');
        const heading = await $('#firstHeading');
        await expect(heading).toHaveText('Version');
    });

    it('should log in', async () => {
        await browser.url('http://localhost:8080/w/index.php?title=Special:UserLogin');
        const usernameInput = await $('#wpName1');
        const passwordInput = await $('#wpPassword1');
        await usernameInput.setValue('Admin');
        await passwordInput.setValue('dockerpass');
        await passwordInput.keys('Enter');
        const userLink = await $('#pt-userpage');
        await expect(userLink).toHaveTextContaining('Admin');
    });

    it('appearance settings should have selected vector radio button', async () => {
        await browser.url('http://localhost:8080/wiki/Special:Preferences#mw-prefsection-rendering');
        const radioBtn = await $('input[type="radio"][value="vector-2022"]');
        await expect(radioBtn).toBeExisting();
        await expect(radioBtn).toBeSelected();
    });

    it('appearance settings should have selected monobook radio button', async () => {
        await browser.url('http://localhost:8080/wiki/Special:Preferences#mw-prefsection-rendering');
        const radioBtn = await $('input[type="radio"][value="monobook"]');
        await expect(radioBtn).toBeExisting();
        await expect(radioBtn).toBeSelected();
    });
});