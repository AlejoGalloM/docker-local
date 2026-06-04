#!/bin/bash

docker ps

#------------------SCF-------------------------#
SCF=$(docker ps | grep :$(SCF_SERVER_TEST_PORT))
SCF=$(echo ${SCF:0:5})
[ "${#SCF}" -gt 1 ] && docker stop $SCF && echo 'SCF Puerto $(SCF_SERVER_TEST_PORT) no disponible' || echo 'SCF Puerto $(SCF_SERVER_TEST_PORT) disponible'
echo "Este es el container del SCF $SCF"
#------------------SCFC-------------------------#
SCFC=$(docker ps -a | grep scf$(APPLICATION_NAME))
SCFC=$(echo ${SCFC:0:5})
[ "${#SCFC}" -gt 1 ] && docker stop $SCFC && docker rm $SCFC && echo 'Contenedor scf$(APPLICATION_NAME) Eliminado' || echo 'SCF Contenedor scf$(APPLICATION_NAME) disponible'
#------------------MQ-------------------------#
MQ=$(docker ps | grep :$(MQ_SERVER_TEST_PORT))
MQ=$(echo ${MQ:0:5})
[ "${#MQ}" -gt 1 ] && docker stop $MQ && echo 'MQ Puerto $(MQ_SERVER_TEST_PORT) no disponible' || echo 'MQ Puerto $(MQ_SERVER_TEST_PORT) disponible'
echo "Este es el container del MQ $MQ"
#------------------MQC-------------------------#
MQC=$(docker ps -a | grep mq$(APPLICATION_NAME))
MQC=$(echo ${MQC:0:5})
[ "${#MQC}" -gt 1 ] && docker stop $MQC && docker rm $MQC && echo 'Contenedor mq$(APPLICATION_NAME) Eliminado' || echo 'MQ Contenedor mq$(APPLICATION_NAME) disponible'
#------------------GO-------------------------#
GO=$(docker ps | grep :$(MOCK_WEB_PORT))
GO=$(echo ${GO:0:5})
[ "${#GO}" -gt 1 ] && docker stop $GO && echo 'GO Puerto $(MOCK_WEB_PORT) no disponible' || echo 'GO Puerto $(MOCK_WEB_PORT) disponible'
echo "Este es el container del GO $GO"
#------------------GOC-------------------------#
GOC=$(docker ps -a | grep go$(APPLICATION_NAME))
GOC=$(echo ${GOC:0:5})
[ "${#GOC}" -gt 1 ] && docker stop $GOC && docker rm $GOC && echo 'Contenedor go$(APPLICATION_NAME) Eliminado' || echo 'GO Contenedor go$(APPLICATION_NAME) disponible'
#------------------DB-------------------------#
DB=$(docker ps | grep :$(DB_PORT))
DB=$(echo ${DB:0:5})
[ "${#DB}" -gt 1 ] && docker stop $DB && echo 'DB Puerto $(DB_PORT) no disponible' || echo 'DB Puerto $(DB_PORT) disponible'
echo "Este es el container del DB $DB"
#------------------DBC-------------------------#
DBC=$(docker ps -a | grep db$(APPLICATION_NAME))
DBC=$(echo ${DBC:0:5})
[ "${#DBC}" -gt 1 ] && docker stop $DBC && docker rm $DBC && echo 'Contenedor db$(APPLICATION_NAME) Eliminado' || echo 'DB Contenedor db$(APPLICATION_NAME) disponible'
