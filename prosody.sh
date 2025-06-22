#!/bin/bash
# DEPENDENCIAS

# 1. Tener un sistema debian con una IP estatica y todo eso. Básicamente lo que te orfrece cualquier VPS de hoy en dia. Este script deberia correr en Ubuntu perfectamente, si lo corres en Ubuntu, cuentame que ha sucedido.

# 2. Tener nginx instalado.

# 3. Tener la siguiente configuracion en el Dominio
# A    @        127.0.0.1 (Direccion IP del servidor)
# A    groups   127.0.0.1
# A    upload   127.0.0.1
# SRV _xmpp-client._tcp.example.com. 18000 IN SRV 0 5 5222 example.com.
# SRV _xmpp-server._tcp.example.com. 18000 IN SRV 0 5 5269 example.com.

# 4. Tener certificado de letsencrypt para el dominio y los subdominios.

if [[ $EUID -ne 0 ]]; then
    echo "Este script se tiene que correr como root." 1>&2
    exit 1
fi

clear
dir=`dirname "$0"`
passwd=`date +%s | sha256sum | base64 | head -c 32 ; echo`

read -p 'Introduzca el dominio: ' dominio
echo "El dominio introducido es $dominio"
certdir="/etc/letsencrypt/live/$dominio"
read -p "Estas seguro? [Y/n] " response

if [ $response == "N" ] || [ $response == "n" ];
then
    echo "Cancelando la instalacion..."
    exit
fi

echo "Instalando programas..."

apt install libnginx-mod-http-perl -y

which hg > /dev/null 2>&1 || apt install mercurial -y
which perl > /dev/null 2>&1 || apt install perl -y
which curl > /dev/null 2>&1 || apt install curl -y
which wget > /dev/null 2>&1 || apt install wget -y
hg clone https://hg.prosody.im/prosody-modules/ /usr/lib/prosody/modules
ls /usr/lib/prosody/modules
sleep 5
which prosody > /dev/null 2>&1 || apt install prosody -y

echo "Escribiendo configuracion en Nginx..."

echo "server {
	server_name upload.$dominio;
	
	root /var/www/upload;

	location / {
	    perl upload::handle;
	}

	client_max_body_size 100m;
}" > /etc/nginx/sites-available/upload

ln -s /etc/nginx/sites-available/upload /etc/nginx/sites-enabled/

mkdir /var/www/upload
chown www-data:www-data /var/www/upload
mkdir -p /usr/local/lib/perl 2>/dev/null
wget -O /usr/local/lib/perl/upload.pm https://git.io/fNZgL

sed -i "s/it-is-secret/$passwd/" /usr/local/lib/perl/upload.pm

FILE=/etc/nginx/modules-enabled/50-mod-http-perl.conf

if [ ! -f "$FILE" ];
then
    cat /etc/nginx/nginx.conf | grep modules/ngx_http_perl_module.so >/dev/null 2>&1 || sed -i '1 i load_module modules/ngx_http_perl_module.so;' /etc/nginx/nginx.conf
fi

cat /etc/nginx/nginx.conf | grep perl_modules > /dev/null 2>&1 || sed -i 's,http {,http {\n\tperl_modules /usr/local/lib/perl;,'  /etc/nginx/nginx.conf
cat /etc/nginx/nginx.conf | grep upload.pm > /dev/null 2>&1 || sed -i 's,perl_modules /usr/local/lib/perl;,\n\tperl_modules /usr/local/lib/perl;\n\tperl_require upload.pm;,' /etc/nginx/nginx.conf

clear
echo "Configurando Prosody..."

mv /etc/prosody/prosody.cfg.lua /etc/prosody/prosody.cfg.lua.ex
cp $dir/prosody.cfg.lua /etc/prosody/

while :
do
    read -p "Inserte su email de contacto (Se usará para que los usuarios de su servidor hablen con usted): " email
 
    read -p "Quiere habilitar el registro de usuarios? (Si se habilita cualquier usuario podrá registrarse) [y/N] " registro
    
    if [ $registro == "Y" ] || [ $registro == "y" ];
    then
	   registro="True"

    else
	   registro="False"
    fi
    
    clear

    echo "Mail de contacto: $email"
    echo "Registro habilitado: $registro"

    read -p "Esta correcto? [Y/n] " opc

    if [ $opc == "Y" ] || [ $opc == "y" ]; then break; fi
done

clear
echo "Configurando prosody..."

sed -i "s/it-is-secret/$passwd/" /etc/prosody/prosody.cfg.lua
sed -i "s/prueba.pr/$dominio/" /etc/prosody/prosody.cfg.lua
sed -i "s/mail@mail.xyz/$email/" /etc/prosody/prosody.cfg.lua

upload="upload.$dominio"
certbot --nginx -d $upload --redirect
prosodyctl --root cert import $upload /etc/letsencrypt/live/
prosodyctl --root cert import $domain /etc/letsencrypt/live

if [[ $registro == "False" ]];
then
    systemctl restart prosody
    clear
    echo "Se ha instalado Prosody correctamete."
    exit
else
    clear
    sed -i 's/allow_registration = false/allow_registration = true/' /etc/prosody/prosody.cfg.lua
    echo "Se ha instalado Prosody correctamente."
fi
