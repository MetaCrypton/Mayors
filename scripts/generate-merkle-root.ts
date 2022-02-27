import { program } from 'commander'
import * as fs from 'fs'
import { parseAccountsMap } from './parse-accounts-map'

program
  .version('0.0.0')
  .requiredOption(
    '-i, --input <path>',
    'input JSON file location containing a list of account addresses'
  )

program.parse(process.argv)

const json = JSON.parse(fs.readFileSync(program.input, { encoding: 'utf8' }))

if (typeof json !== 'object') throw new Error('Invalid JSON')

console.log(JSON.stringify(parseAccountsMap(json), null, 2))
