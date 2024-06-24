import { Contract } from 'ethers'
import { waffle, ethers } from 'hardhat'

import { Fixture } from 'ethereum-waffle'
import { ImmutableStateTest } from '../typechain'
import { expect } from './shared/expect'
import completeFixture from './shared/completeFixture'
import { v1FactoryFixture } from './shared/externalFixtures'

describe('ImmutableState', () => {
  const fixture: Fixture<{
    factoryV1: Contract
    nft: Contract
    state: ImmutableStateTest
  }> = async (wallets, provider) => {
    const { factory: factoryV1 } = await v1FactoryFixture(wallets, provider)
    const { nft } = await completeFixture(wallets, provider)

    const stateFactory = await ethers.getContractFactory('ImmutableStateTest')
    const state = (await stateFactory.deploy(factoryV1.address, nft.address)) as ImmutableStateTest

    return {
      nft,
      factoryV1,
      state,
    }
  }

  let factoryV1: Contract
  let nft: Contract
  let state: ImmutableStateTest

  let loadFixture: ReturnType<typeof waffle.createFixtureLoader>

  before('create fixture loader', async () => {
    loadFixture = waffle.createFixtureLoader(await (ethers as any).getSigners())
  })

  beforeEach('load fixture', async () => {
    ;({ factoryV1, nft, state } = await loadFixture(fixture))
  })

  it('bytecode size', async () => {
    expect(((await state.provider.getCode(state.address)).length - 2) / 2).to.matchSnapshot()
  })

  describe('#factoryV1', () => {
    it('points to v1 core factory', async () => {
      expect(await state.factoryV1()).to.eq(factoryV1.address)
    })
  })

  describe('#positionManager', () => {
    it('points to NFT', async () => {
      expect(await state.positionManager()).to.eq(nft.address)
    })
  })
})
