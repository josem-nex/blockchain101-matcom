# English
## ScoreTracker
Initially, each student had to register their wallets in the ScoreTracker contract in Sepolia.
The proxy address is `0xB4077719b59B40Dc5199a4B6dcAAd6D6E0919984` and the implementation (ScoreTracker.sol): `0xE9BFC24eb6fc26f892b45DA75a6182A00C2F6B47`.
## Registration
- The registration was carried out through a Merkle Tree where each student had to obtain their corresponding proof, in Solution/MerkleTree.ts is the TypeScript code I used.
- In addition, other wallets used by each person could/should be added, for this, a signature had to be obtained from the main wallet with the corresponding hash. Through another contract in Remix, I obtained the hash and then signed it using TypeScript, thus adding my remaining wallets (e.g., 0xdC10FEDf9B41C1496f4217521250756C8FBbBc0C where my POAPs are located).

-----------------------------------------------------------------

# Español
## ScoreTracker
Inicialmente cada estudiante debió registrar sus wallets en el contrato ScoreTracker en Sepolia.
La dirección del proxy es `0xB4077719b59B40Dc5199a4B6dcAAd6D6E0919984` y la implementación (ScoreTracker.sol): `0xE9BFC24eb6fc26f892b45DA75a6182A00C2F6B47`.
## Registro
- El registro se realizó mediante un Merkle Tree donde cada estudiante debió obtener su proof correspondiente, en Solution/MerkleTree.ts está el código que utilicé de Typescript.
- Además se podían/debían añadir otras wallets utilizadas por cada persona, para ello se debía obtener una firma de la wallet principal con el hash correspondiente. Mediante otro contrato en Remix obtuve el hash y luego lo firme mediante Typescript, añadiendo así mis wallets restantes (ej: 0xdC10FEDf9B41C1496f4217521250756C8FBbBc0C donde se encuentran mis POAPs).