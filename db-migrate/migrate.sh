set_aws_configure_and_get_secretmanager() {
    echo "[START]: set_aws_configure_and_get_secret-manager"

    aws configure set region ap-northeast-2
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
    
    DATABASE_URL=$(aws secretsmanager get-secret-value --secret-id $BRANCH-db-migrate | jq --raw-output '.SecretString' | jq -r .DATABASE_URL)
    DATABASE_USER=$(aws secretsmanager get-secret-value --secret-id $BRANCH-db-migrate | jq --raw-output '.SecretString' | jq -r .DATABASE_USER)
    DATABASE_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $BRANCH-db-migrate | jq --raw-output '.SecretString' | jq -r .DATABASE_PASSWORD)
    GITHUB_PAT=$(aws secretsmanager get-secret-value --secret-id $BRANCH-db-migrate | jq --raw-output '.SecretString' | jq -r .GITHUB_PAT)

    wget -O /environment/.env --header="x-api-key: $X_API_KEY" https://xe2rikyx3b.execute-api.ap-northeast-2.amazonaws.com/gateway-lambda-secrets/get-secret-env\?name\=$SECRET_MANAGER_NAME    

    echo "[END]: set_aws_configure_and_get_secret-manager"
}

db_repo_clone() {
    echo "[START]: db_repo_clone"

    git clone https://$GITHUB_PAT:@[GITHUB-URL]/$BASE_DIR.git --branch=$BRANCH

    cd $BASE_DIR/migrations/liquibase/changelog

    echo "[END]: db_repo_clone"
}

write_liquibase_properties() {
    echo "[START]: write_liquibase_properties"

    rm -rf ./liquibase.properties

    local LIQUIBASE_PROPERTIES_URL
    LIQUIBASE_PROPERTIES_URL="url: jdbc:postgresql://$DATABASE_URL:5432/$TARGET_DATABASE"
    local LIQUIBASE_PROPERTIES_USERNAME
    LIQUIBASE_PROPERTIES_USERNAME="username: $DATABASE_USER"
    local LIQUIBASE_PROPERTIES_PASSWORD
    LIQUIBASE_PROPERTIES_PASSWORD="password: $DATABASE_PASSWORD"

    echo $LIQUIBASE_PROPERTIES_URL >> liquibase.properties
    echo $LIQUIBASE_PROPERTIES_USERNAME >> liquibase.properties
    echo $LIQUIBASE_PROPERTIES_PASSWORD >> liquibase.properties
    echo changeLogFile: changelog.xml >> liquibase.properties
    echo secureParsing="false" >> liquibase.properties
    
    echo "[END]: write_liquibase_properties"
}

migrate_database_liquibase() {
    echo "[START]: migrate_database_liquibase"

    liquibase   --secureParsing=false \
                --log-level=INFO \
                --defaults-file=./liquibase.properties \
                --changeLogFile=./changelog.xml update

    echo "[END]: migrate_database_liquibase"
}

clear_data() {
    echo "[START]: clear_data"

    rm -rf ~/.aws
    rm -rf liquibase.properties
    rm -rf /home/$BASE_DIR

    echo "[END]: clear_data"
}

_main() {
    # aws configure 설정 및 secret-manager 에서 데이터베이스 정보 가져오기
    set_aws_configure_and_get_secretmanager

    # 데이터베이스 레포지토리 클론
    db_repo_clone

    # liquibase.properties 파일 생성
    write_liquibase_properties
    
    # liquibase 데이터베이스 마이그레이션
    migrate_database_liquibase

    # 데이터베이스 마이그레이션 후 저장된 데이터 삭제
    clear_data
}

_main "$@"