import { Fixture } from 'ethereum-waffle'
import { constants, Contract, ContractTransaction, Wallet } from 'ethers'
import { waffle, ethers } from 'hardhat'
import { IWSEI, MockTimeSwapRouter02 } from '../typechain'
import completeFixture from './shared/completeFixture'
import { expect } from './shared/expect'

describe('PeripheryPaymentsExtended', function () {
  let wallet: Wallet

  const routerFixture: Fixture<{
    wsei: IWSEI
    router: MockTimeSwapRouter02
  }> = async (wallets, provider) => {
    const { wsei, router } = await completeFixture(wallets, provider)

    return {
      wsei,
      router,
    }
  }

  let router: MockTimeSwapRouter02
  let wsei: IWSEI

  let loadFixture: ReturnType<typeof waffle.createFixtureLoader>

  before('create fixture loader', async () => {
    ;[wallet] = await (ethers as any).getSigners()
    loadFixture = waffle.createFixtureLoader([wallet])
  })

  beforeEach('load fixture', async () => {
    ;({ wsei, router } = await loadFixture(routerFixture))
  })

  describe('wrapETH', () => {
    it('increases router WSEI balance by value amount', async () => {
      const value = ethers.utils.parseEther('1')

      const wseiBalancePrev = await wsei.balanceOf(router.address)
      await router.wrapETH(value, { value })
      const wseiBalanceCurrent = await wsei.balanceOf(router.address)

      expect(wseiBalanceCurrent.sub(wseiBalancePrev)).to.equal(value)
      expect(await wsei.balanceOf(wallet.address)).to.equal('0')
      expect(await router.provider.getBalance(router.address)).to.equal('0')
    })
  })
})
