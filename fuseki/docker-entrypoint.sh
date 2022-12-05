#!/bin/bash
#   Licensed to the Apache Software Foundation (ASF) under one or more
#   contributor license agreements.  See the NOTICE file distributed with
#   this work for additional information regarding copyright ownership.
#   The ASF licenses this file to You under the Apache License, Version 2.0
#   (the "License"); you may not use this file except in compliance with
#   the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

set -e

if [ ! -f "$FUSEKI_BASE/shiro.ini" ] ; then
  # First time
  echo "###################################"
  echo "Initializing Apache Jena Fuseki"
  echo ""
  cp "$FUSEKI_HOME/shiro.ini" "$FUSEKI_BASE/shiro.ini"
  if [ -z "$ADMIN_PASSWORD" ] ; then
    ADMIN_PASSWORD=$(pwgen -s 15)
    echo "Randomly generated admin password:"
    echo ""
    echo "admin=$ADMIN_PASSWORD"
  fi
  echo ""
  echo "###################################"
fi

if [ -d "/fuseki-extra" ] && [ ! -d "$FUSEKI_BASE/extra" ] ; then
  ln -s "/fuseki-extra" "$FUSEKI_BASE/extra" 
fi

# $ADMIN_PASSWORD only modifies if ${ADMIN_PASSWORD}
# is in shiro.ini
if [ -n "$ADMIN_PASSWORD" ] ; then
  export ADMIN_PASSWORD
  envsubst '${ADMIN_PASSWORD}' < "$FUSEKI_BASE/shiro.ini" > "$FUSEKI_BASE/shiro.ini.$$" && \
    mv "$FUSEKI_BASE/shiro.ini.$$" "$FUSEKI_BASE/shiro.ini"
  unset ADMIN_PASSWORD # Don't keep it in memory
  export ADMIN_PASSWORD
fi

# Convert env to datasets in the form FUSEKI_DATASET_DATASET_X=dataset_x
printenv | egrep "^FUSEKI_DATASET_" | while read env_var
do
    dataset=$(echo $env_var | egrep -o "=.*$" | sed 's/^=//g')
    conffile="${FUSEKI_BASE}/configuration/${dataset}.ttl"

    if [ -f "$conffile" ]; then
      echo "${conffile} exists, not overwriting"
      # skip if exists
      continue
    fi

    echo "Creating dataset ${dataset} at ${conffile}"
    mkdir -p "${FUSEKI_BASE}/configuration"

    cat << EOF > "${conffile}"
@prefix :       <#> .
@prefix fuseki: <http://jena.apache.org/fuseki#> .
@prefix ja:     <http://jena.hpl.hp.com/2005/11/Assembler#> .
@prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:   <http://www.w3.org/2000/01/rdf-schema#> .
@prefix tdb2:   <http://jena.apache.org/2016/tdb#> .
tdb2:GraphTDB  rdfs:subClassOf  ja:Model .
ja:ModelRDFS  rdfs:subClassOf  ja:Model .
ja:RDFDatasetSink  rdfs:subClassOf  ja:RDFDataset .
<http://jena.hpl.hp.com/2008/tdb#DatasetTDB>
        rdfs:subClassOf  ja:RDFDataset .
tdb2:GraphTDB2  rdfs:subClassOf  ja:Model .
<http://jena.apache.org/text#TextDataset>
        rdfs:subClassOf  ja:RDFDataset .
ja:RDFDatasetZero  rdfs:subClassOf  ja:RDFDataset .
:service_tdb_all  rdf:type  fuseki:Service ;
        rdfs:label       "TDB2 ${dataset}" ;
        fuseki:dataset   :tdb_dataset_readwrite ;
        fuseki:endpoint  [ fuseki:name       "sparql" ;
                           fuseki:operation  fuseki:query
                         ] ;
        fuseki:endpoint  [ fuseki:name       "update" ;
                           fuseki:operation  fuseki:update
                         ] ;
        fuseki:endpoint  [ fuseki:operation  fuseki:gsp-rw ] ;
        fuseki:endpoint  [ fuseki:name       "query" ;
                           fuseki:operation  fuseki:query
                         ] ;
        fuseki:endpoint  [ fuseki:name       "get" ;
                           fuseki:operation  fuseki:gsp-r
                         ] ;
        fuseki:endpoint  [ fuseki:name       "data" ;
                           fuseki:operation  fuseki:gsp-rw
                         ] ;
        fuseki:endpoint  [ fuseki:operation  fuseki:update ] ;
        fuseki:endpoint  [ fuseki:operation  fuseki:query ] ;
        fuseki:name      "${dataset}" .
ja:ViewGraph  rdfs:subClassOf  ja:Model .
ja:GraphRDFS  rdfs:subClassOf  ja:Model .
tdb2:DatasetTDB  rdfs:subClassOf  ja:RDFDataset .
<http://jena.hpl.hp.com/2008/tdb#GraphTDB>
        rdfs:subClassOf  ja:Model .
ja:DatasetTxnMem  rdfs:subClassOf  ja:RDFDataset .
tdb2:DatasetTDB2  rdfs:subClassOf  ja:RDFDataset .
ja:RDFDatasetOne  rdfs:subClassOf  ja:RDFDataset .
ja:MemoryDataset  rdfs:subClassOf  ja:RDFDataset .
:tdb_dataset_readwrite
        rdf:type       tdb2:DatasetTDB2 ;
        tdb2:location  "${FUSEKI_BASE}/databases/${dataset}" ;
        tdb2:unionDefaultGraph true ;
        .
ja:DatasetRDFS  rdfs:subClassOf  ja:RDFDataset .
EOF
done

exec "${FUSEKI_HOME}/fuseki-server"