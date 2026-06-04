
#!/bin/bash

docker ps

#------------------TMG-------------------------#
TMG=$(docker ps | grep :$(TMG_PORT))
TMG=$(echo ${TMG:0:5})
[ "${#TMG}" -gt 1 ] && docker stop $TMG && echo 'TMG Puerto $(TMG_PORT) no disponible' || echo 'TMG Puerto $(TMG_PORT) disponible'
echo "Este es el container del TMG $TMG"
#------------------TMGC-------------------------#
TMGC=$(docker ps -a | grep tmg$(APPLICATION_NAME))
TMGC=$(echo ${TMGC:0:5})
[ "${#TMGC}" -gt 1 ] && docker stop $TMGC && docker rm $TMGC && echo 'Contenedor tmg$(APPLICATION_NAME) Eliminado' || echo 'TMG Contenedor tmg$(APPLICATION_NAME) disponible'
#------------------MQ-------------------------#
MQ=$(docker ps | grep :$(MQ_SERVER_TEST_PORT))
MQ=$(echo ${MQ:0:5})
[ "${#MQ}" -gt 1 ] && docker stop $MQ && echo 'MQ Puerto $(MQ_SERVER_TEST_PORT) no disponible' || echo 'MQ Puerto $(MQ_SERVER_TEST_PORT) disponible'
echo "Este es el container del MQ $MQ"
#------------------MQC-------------------------#
MQC=$(docker ps -a | grep mq$(APPLICATION_NAME))
MQC=$(echo ${MQC:0:5})
[ "${#MQC}" -gt 1 ] && docker stop $MQC && docker rm $MQC && echo 'Contenedor mq$(APPLICATION_NAME) Eliminado' || echo 'MQ Contenedor mq$(APPLICATION_NAME) disponible'
