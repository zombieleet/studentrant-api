#!/usr/bin/env bash
export NODE_ENV=test



if [[ ! -e "${HOME}/studentrant_test_db1/" ]] || \
       [[ ! -e "${HOME}/studentrant_test_db2/" ]]  || [[ ! -e "${HOME}/studentrant_test_db3/" ]]; then

    proces=(27071 27081 27091);

    for i in "${proces[@]}";do
	mapfile procs <<<$(lsof -t -i:$i)
	procLen=${#procs[@]} # cjtrl + back tick no dey respond eform my p.c
	(( procLen >= 1 )) && {
            for j in "${procs[@]}";do
		echo "$j"
		(( ${#j} > 1 )) && kill -9 $j ; sleep 2
            done
	}
    done

    mkdir -p "${HOME}/studentrant_test_db1/"
    mkdir -p "${HOME}/studentrant_test_db2/"
    mkdir -p "${HOME}/studentrant_test_db3/"

    mongod --dbpath "${HOME}/studentrant_test_db1/" --port 27071  --replSet studentrant_test --fork --syslog &>/dev/null
    sleep 5
    mongod --dbpath "${HOME}/studentrant_test_db2/" --port 27081 --replSet studentrant_test --fork --syslog &>/dev/null
    sleep 5
    mongod --dbpath "${HOME}/studentrant_test_db3/" --port 27091 --replSet studentrant_test --fork --syslog &>/dev/null
    sleep 5

    mongo --port 27071 <<EOF
use studentrant
if ( rs.status().codeName === "NotYetInitialized" ) {

   rs.initiate({
      _id: "studentrant_test",
      members: [
         { _id: 0, host: "127.0.0.1:27071", priority: 1   },
         { _id: 1, host: "127.0.0.1:27081", priority: 0.5 },
	 { _id: 2, host: "127.0.0.1:27091", priority: 0.5 }
      ]
   });
   sleep(1500); // sleep for 5 seconds
}
sleep(15000);
db.dropDatabase();

EOF
fi

pidof mongod

[[ $? == 1 ]] && {
    mongod --dbpath "${HOME}/studentrant_test_db1/" --port 27071  --replSet studentrant_test --fork --syslog
    sleep 5
    mongod --dbpath "${HOME}/studentrant_test_db2/" --port 27081 --replSet studentrant_test --fork --syslog
    sleep 5
    mongod --dbpath "${HOME}/studentrant_test_db3/" --port 27091 --replSet studentrant_test --fork --syslog
    sleep 5

}
mongo --port 27071 <<EOF
use studentrant
db.dropDatabase()
EOF

export DEFAULT_TIMEOUT_INTERVAL=50000
export JASMINE_CONFIG_PATH="jasmine.json"

node --experimental-modules ./node_modules/.bin/istanbul --config=.istanbul.yml cover ./jasmine-run-test.js
