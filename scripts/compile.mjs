import { readFile, mkdir, writeFile } from "node:fs/promises";
import solc from "solc";
const source = await readFile("contracts/KiteAuthorizationVault.sol", "utf8");
const input = { language: "Solidity", sources: { "KiteAuthorizationVault.sol": { content: source } }, settings: { optimizer: { enabled: true, runs: 200 }, outputSelection: { "*": { "*": ["abi", "evm.bytecode.object"] } } } };
const output = JSON.parse(solc.compile(JSON.stringify(input)));
const errors = output.errors?.filter((error) => error.severity === "error") ?? [];
if (errors.length) { for (const error of errors) console.error(error.formattedMessage); process.exit(1); }
await mkdir("build", { recursive: true });
const artifact = output.contracts["KiteAuthorizationVault.sol"].KiteAuthorizationVault;
await writeFile("build/KiteAuthorizationVault.json", JSON.stringify({ abi: artifact.abi, bytecode: artifact.evm.bytecode.object }, null, 2));
console.log(`compiled KiteAuthorizationVault (${artifact.evm.bytecode.object.length / 2} bytes)`);
