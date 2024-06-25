import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '@dragonswap/v2-core/artifacts/contracts/DragonswapV2Factory.sol/DragonswapV2Factory.json'
import { abi as FACTORY_V1_ABI, bytecode as FACTORY_V1_BYTECODE } from '@dragonswap/core/artifacts/contracts/DragonswapFactory.sol/DragonswapFactory.json'
import { Fixture } from 'ethereum-waffle'
import { ethers, waffle } from 'hardhat'
import { IWSEI, MockTimeSwapRouter02 } from '../../typechain'

import WSEI from '../contracts/WSEI.json'
import { Contract } from '@ethersproject/contracts'
import { constants } from 'ethers'

import {
  abi as NFT_POSITION_MANAGER_ABI,
  bytecode as NFT_POSITION_MANAGER_BYTECODE,
} from '@dragonswap/v2-periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json'

const wseiFixture: Fixture<{ wsei: IWSEI }> = async ([wallet]) => {
  const wsei = (await waffle.deployContract(wallet, {
    bytecode: WSEI.bytecode,
    abi: WSEI.abi,
  })) as IWSEI

  return { wsei }
}

export const v1FactoryFixture: Fixture<{ factory: Contract }> = async ([wallet]) => {
  const factory = await waffle.deployContract(
    wallet,
    {
      bytecode: FACTORY_V1_BYTECODE,
      abi: FACTORY_V1_ABI,
    },
    ["0x0000000000000000000000000000000000000001"]
  )

  return { factory }
}

const v2CoreFactoryFixture: Fixture<Contract> = async ([wallet]) => {
  return await waffle.deployContract(wallet, {
    bytecode: FACTORY_BYTECODE,
    abi: FACTORY_ABI,
  })
}

export const v2RouterFixture: Fixture<{
  wsei: IWSEI
  factoryV1: Contract
  factory: Contract
  nft: Contract
  router: MockTimeSwapRouter02
}> = async ([wallet], provider) => {
  const { wsei } = await wseiFixture([wallet], provider)
  const { factory: factoryV1 } = await v1FactoryFixture([wallet], provider)
  const factory = await v2CoreFactoryFixture([wallet], provider)

  const nft = await waffle.deployContract(
    wallet,
    {
      bytecode: NFT_POSITION_MANAGER_BYTECODE,
      abi: NFT_POSITION_MANAGER_ABI,
    },
    [factory.address, wsei.address, constants.AddressZero]
  )

  const router = (await (await ethers.getContractFactory('MockTimeSwapRouter02')).deploy(
    factoryV1.address,
    factory.address,
    nft.address,
    wsei.address
  )) as MockTimeSwapRouter02

  return { wsei, factoryV1, factory, nft, router }
}
