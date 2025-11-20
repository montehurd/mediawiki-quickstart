
'use strict'

describe('Quickstart Selenium', () => {
  it('should show Version heading', async() => {
    await browser.url('http://localhost:8080/wiki/Special:Version')
    const heading = await $('#firstHeading')
    await expect(heading).toHaveText('Version')
  })

  it('should log in', async() => {
    await browser.url('http://localhost:8080/w/index.php?title=Special:UserLogin')
    const usernameInput = await $('#wpName1')
    const passwordInput = await $('#wpPassword1')
    await usernameInput.setValue('Admin')
    await passwordInput.setValue('dockerpass')
    const loginButton = await $('#wpLoginAttempt')
    await loginButton.click()
    const userLink = await $('a[href="/wiki/User:Admin"]')
    await expect(userLink).toExist()
  })

  it('appearance settings should have selected vector radio button', async() => {
    await browser.url('http://localhost:8080/wiki/Special:Preferences#mw-prefsection-rendering')
    const radioBtn = await $('input[type="radio"][value="vector-2022"]')
    await expect(radioBtn).toExist()
    await expect(radioBtn).toBeSelected()
  })

  it('appearance settings should have selected monobook radio button', async() => {
    await browser.url('http://localhost:8080/wiki/Special:Preferences#mw-prefsection-rendering')
    const radioBtn = await $('input[type="radio"][value="monobook"]')
    await expect(radioBtn).toExist()
    await expect(radioBtn).toBeSelected()
  })
})