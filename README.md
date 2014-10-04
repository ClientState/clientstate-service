You have node and npm installed? Good.

Run `npm install`.

Do you have redis installed with `redis-server` on your PATH? Good.

Run `./run_tests.sh`

If you want to talk to github to test a bad authkey:

    TEST_USE_NETWORK=yes ./run_tests.sh
