#!/bin/bash
# Version: 1.0.0
# Desenvolvido por Jorge Nunes  Suporte via WhatsApp 11-99962-3179
# Suporte por email jcvn@jcvn.com.br 
#For use on clean Ubuntu 16.04 only!!!

ARQLOG=/var/log/traccar.log
USERHOME=/tmp
MYSQLPASSWORD=traccar
DBTRACCAR=traccardb
HOST=127.0.0.1
IP=$(ip -f inet a|grep -oP "(?<=inet ).+(?=\/)" | sed -n 2p)
ProgressBar() {
   tput civis
   for X in $(seq 20)
   do
     for i in ..
     do
       echo -en "\033[1D$i"
       sleep .1
     done
   done
   tput cnorm
}
systemctl stop traccar
cd /opt/traccar && rm -rf *
cd /tmp && rm -rf traccar* && rm -rf README.txt
echo -en " Removendo VersÃµes Anteriores, aguarde ..........." ;ProgressBar; echo -e " [\033[0;32m ok\033[m ]"
echo
echo -en " Atualizando o Sistema, aguarde ..................";ProgressBar; echo -e " [\033[0;32m ok\033[m ]"
#echo "Atualizando o Sistema, Aguarde..."
sudo apt-get update -y >> $ARQLOG
sudo apt-get upgrade -y >> $ARQLOG
echo
echo -en " Instalando Unzip, aguarde .......................";ProgressBar; echo -e " [\033[0;32m ok\033[m ]"
#echo "Instalando Unzip, Aguarde..."
sudo apt-get install -y unzip >> $ARQLOG 2>&1
echo
echo -en " Instalando MySQL 5.7, aguarde ...................";ProgressBar; echo -e " [\033[0;32m ok\033[m ]"
#echo "Instalando MySQL 5.7 Aguarde..."
echo "mysql-server-5.7 mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password root" | sudo debconf-set-selections
apt-get -y install mysql-server-5.7 mysql-client >> $ARQLOG 2>&1
mysql -u root -proot -e "use mysql; UPDATE user SET authentication_string=PASSWORD('$MYSQLPASSWORD') WHERE User='root'; flush privileges;" >> $ARQLOG 2>&1
mysql -u root -p$MYSQLPASSWORD <<MYSQL_SCRIPT 
CREATE DATABASE $DBTRACCAR DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
FLUSH PRIVILEGES;
MYSQL_SCRIPT
echo
echo " Instalando Traccar 4.6"
cd $USERHOME
wget https://github.com/traccar/traccar/releases/download/v4.6/traccar-linux-64-4.6.zip >> $ARQLOG 2>&1
unzip traccar-linux-*.zip >> $ARQLOG 2>&1
sudo ./traccar.run >> $ARQLOG 2>&1
echo
echo -en " Configurando a Plataforma Traccar, aguarde ......";ProgressBar; echo -e " [\033[0;32m ok\033[m ]"
#echo "Configurando Traccar, Aguarde..."
sudo tee /opt/traccar/conf/traccar.xml <<EOF
<?xml version='1.0' encoding='UTF-8'?>

<!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>

<properties>

    <entry key="config.default">./conf/default.xml</entry>

    <entry key='web.port'>80</entry>

    <entry key='geocoder.enable'>false</entry>

    <entry key='database.driver'>com.mysql.jdbc.Driver</entry> 
    <entry key='database.url'>jdbc:mysql://$HOST:3306/$DBTRACCAR?serverTimezone=UTC&amp;useSSL=false&amp;allowMultiQueries=true&amp;autoReconnect=true&amp;useUnicode=yes&amp;characterEncoding=UTF-8&amp;sessionVariables=sql_mode=''</entry>
    <entry key='database.user'>root</entry> 
    <entry key='database.password'>$MYSQLPASSWORD</entry>
    
    <entry key='server.timeout'>120</entry>

</properties>
EOF
echo -en " Configurando Jobs para limpeza de logs, aguarde .";ProgressBar; echo -e " [\033[0;32m ok\033[m ]"
#echo "Configurando Jobs para limpeza de logs, Aguarde..."
printf '#!/bin/sh\nfind /opt/traccar/logs/ -mtime +5 -type f -delete\n' > /etc/cron.daily/traccar-clear-logs && chmod +x /etc/cron.daily/traccar-clear-logs
echo
echo -en " Iniciando a Plataforma Traccar, aguarde ..........";ProgressBar; echo -e " [\033[0;32m ok\033[m ]"
#echo "Iniciando a Plataforma Traccar, Aguarde..."
sudo systemctl start traccar >> $ARQLOG 2>&1
echo
echo " Parabens InstalaÃ§Ã£o Finalizada com Sucesso!!!"
echo
echo " Acesse a Plataforma pelo Browser atraves do URL do Servidor http://$IP "
