$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

function Invoke-DockerChecked {
    param([string[]]$DockerArgs)
    & docker @DockerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Docker завершился с кодом ${LASTEXITCODE}: $($DockerArgs -join ' ')"
    }
}

Invoke-DockerChecked -DockerArgs @('compose', '-p', 'video-labs', 'up', '-d', '--wait')

foreach ($file in @('01_3nf.sql', '02_seed_3nf.sql', '03_data_vault.sql',
                    '04_load_vault.sql', '05_checks.sql')) {
    Invoke-DockerChecked -DockerArgs @('cp', "Лаб 1/$file", "video-labs-postgres-1:/tmp/$file")
    Invoke-DockerChecked -DockerArgs @('exec', 'video-labs-postgres-1', 'psql',
                           '-v', 'ON_ERROR_STOP=1', '-U', 'lab', '-d', 'video_rental',
                           '-f', "/tmp/$file")
}

Invoke-DockerChecked -DockerArgs @('cp', 'Лаб 1/mongo_video_rental.js',
                       'video-labs-mongo-1:/tmp/mongo_video_rental.js')
Invoke-DockerChecked -DockerArgs @('exec', 'video-labs-mongo-1', 'mongosh', '--quiet',
                       '/tmp/mongo_video_rental.js')
Invoke-DockerChecked -DockerArgs @('cp', 'Лаб 3/mongo_basics.js',
                       'video-labs-mongo-1:/tmp/mongo_basics.js')
Invoke-DockerChecked -DockerArgs @('exec', 'video-labs-mongo-1', 'mongosh', '--quiet',
                       '/tmp/mongo_basics.js')

foreach ($file in @('neo4j_seed.cypher', 'neo4j_queries.cypher')) {
    Invoke-DockerChecked -DockerArgs @('cp', "Лаб 4/$file", "video-labs-neo4j-1:/tmp/$file")
}
Invoke-DockerChecked -DockerArgs @('exec', 'video-labs-neo4j-1', 'cypher-shell',
                       '-u', 'neo4j', '-p', 'lab_password_neo4j',
                       '-f', '/tmp/neo4j_seed.cypher')
Invoke-DockerChecked -DockerArgs @('exec', 'video-labs-neo4j-1', 'cypher-shell',
                       '-u', 'neo4j', '-p', 'lab_password_neo4j',
                       '-f', '/tmp/neo4j_queries.cypher')
