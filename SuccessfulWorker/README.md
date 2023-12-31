# English
## successfulWorkers
The objective of this challenge is to register as a successfulWorker in the contract `0xCd92435512f7AD66A210c641416a4D91369c3cBd` (MoneyFactory.sol) which also creates a clone of the contract: `0x12B47058Dee1B24C06501df2a128D43Af9Bb9831` (MagicMoneyMaker.sol)

## My solution (successfulWorker.sol)
To achieve being a successfulWorker, I used the Clones library from openzeppelin to predict the address at which the MagicMoneyMaker clone would be created since it does not have a receive() function and the way to enter money would be before creating it, thus it could meet the requirements of the mine function. Also, to achieve a *workSession* > 1 my contract performs a *reentrancy* and when it receives a call it calls the mine function again with different parameters to reactivate it, thus achieving to be a successfulworker.

-----------------------------------------------------

# Español
## successfulWorkers
El objetivo de este challange es registrarse como successfulWorker en el contrato `0xCd92435512f7AD66A210c641416a4D91369c3cBd` (MoneyFactory.sol) el cuál además crea un clone del contrato: `0x12B47058Dee1B24C06501df2a128D43Af9Bb9831` (MagicMoneyMaker.sol)

## Mi solución (successfulWorker.sol)
Para lograr ser un successfulWorker, usé la librería Clones de openzeppelin para predecir la dirección en la cuál se crearía el clone de MagicMoneyMaker pues este no tiene función receive() y la manera de ingresarle dinero sería antes de crearlo, así se podría cumplir lo requerido por la función mine. Además para lograr un *workSession* > 1 mi contrato realiza un *reentrancy* y cuando recibe un llamado él vuelve a llamar a la función mine con parámetros diferentes para que se vuelva activar, logrando así ser un successfulworker.