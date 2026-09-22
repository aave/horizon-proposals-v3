/**
 * Lists every Horizon aUSTB / aUSCC holder with a non-zero balance at a block and checks each one
 * against the Superstate AllowlistV4.2 for its token.
 *
 * usage: RPC_MAINNET=<url> npx tsx scripts/superstate-allowlist-holders.ts [block]
 */
import {createPublicClient, http, parseAbiItem, type Address} from 'viem';
import {mainnet} from 'viem/chains';

const ALLOWLIST_V4_2: Address = '0xBcBC2b4FB2AbE1C598C9ea91E0b03338e4728D1f';
const ATOKEN_DEPLOY_BLOCK = 23132230n;
const LOG_RANGE = 400_000n;

const RESERVES = [
  {
    name: 'USTB',
    underlying: '0x43415eB6ff9DB7E26A15b704e7A3eDCe97d31C4e',
    aToken: '0x4E58a2E433A739726134c83d2f07b2562e8dFdB3',
  },
  {
    name: 'USCC',
    underlying: '0x14d60E7FDC0D71d8611742720E4C50E7a974020c',
    aToken: '0x08b798c40b9AB931356d9aB4235F548325C4cb80',
  },
] as const;

const transfer = parseAbiItem(
  'event Transfer(address indexed from, address indexed to, uint256 value)',
);
const balanceOf = parseAbiItem('function balanceOf(address) view returns (uint256)');
const isAllowed = parseAbiItem(
  'function isAllowed(address addr, address token) view returns (bool)',
);
const allowlist = parseAbiItem('function allowlist() view returns (address)');

async function main() {
  const rpc = process.env.RPC_MAINNET;
  if (!rpc) throw new Error('RPC_MAINNET not set');
  const client = createPublicClient({chain: mainnet, transport: http(rpc)});
  const blockNumber = process.argv[2] ? BigInt(process.argv[2]) : await client.getBlockNumber();

  let lockedOut = 0;
  for (const reserve of RESERVES) {
    const live = await client.readContract({
      address: reserve.underlying,
      abi: [allowlist],
      functionName: 'allowlist',
      blockNumber,
    });
    if (live.toLowerCase() !== ALLOWLIST_V4_2.toLowerCase()) {
      throw new Error(`${reserve.name} reads ${live} at block ${blockNumber}, not AllowlistV4.2`);
    }

    const participants = new Set<Address>();
    for (let from = ATOKEN_DEPLOY_BLOCK; from <= blockNumber; from += LOG_RANGE) {
      const to = from + LOG_RANGE - 1n < blockNumber ? from + LOG_RANGE - 1n : blockNumber;
      const logs = await client.getLogs({
        address: reserve.aToken,
        event: transfer,
        fromBlock: from,
        toBlock: to,
      });
      for (const log of logs) {
        participants.add(log.args.from!);
        participants.add(log.args.to!);
      }
    }
    participants.delete('0x0000000000000000000000000000000000000000');

    const holders: {holder: Address; balance: bigint; allowed: boolean}[] = [];
    for (const holder of participants) {
      const balance = await client.readContract({
        address: reserve.aToken,
        abi: [balanceOf],
        functionName: 'balanceOf',
        args: [holder],
        blockNumber,
      });
      if (balance === 0n) continue;
      const allowed = await client.readContract({
        address: ALLOWLIST_V4_2,
        abi: [isAllowed],
        functionName: 'isAllowed',
        args: [holder, reserve.underlying],
        blockNumber,
      });
      holders.push({holder, balance, allowed});
    }
    holders.sort((a, b) => a.holder.toLowerCase().localeCompare(b.holder.toLowerCase()));

    const blocked = holders.filter((h) => !h.allowed);
    lockedOut += blocked.length;
    console.log(
      `a${reserve.name}: ${holders.length} holders at block ${blockNumber}, ${blocked.length} not allowed`,
    );
    for (const h of holders) {
      console.log(`  ${h.allowed ? 'ok     ' : 'BLOCKED'} ${h.holder} ${h.balance}`);
    }
    console.log(`  solidity: [${holders.map((h) => h.holder).join(', ')}]`);
  }

  if (lockedOut > 0) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
