#!/bin/bash

reset='\033[0m'
black='\033[0;30m'
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
white='\033[0;37m'

if [ "$(whoami)" = "root" ]; then

    echo -en "Nom de domaine : "
    read website
    if [ "${website}" ]; then

		defaultUser=$(echo ${website} | sed 's/\..*//g')

        echo -en "Nom d'utilisateur (${defaultUser}) : "
        read user
        if [ ! "${user}" ]; then
            user=${defaultUser}
        fi

		pathHome="/home/${user}"
		pathGit="/home/git/repositories/${user}"
        
		if [ ! -d "${pathHome}" ]; then
	
		    # Création de l'utilisateur
		    # ------------------------------
	        useradd ${user}
	        if id -u ${user} >/dev/null 2>&1; then
	            echo -e "${green} - - - Création de l'utilisateur${reset}"
	        else
	            echo -e "${red} - - - Erreur lors de la création de l'utilisateur${reset}"
	        fi
	        
	        # Création du projet GIT
		    # ------------------------------
            echo -en "Créer un projet Git ? [y/n] "
            read useGit
		    if [ "${useGit}" = "y" ]; then
		        if [ ! -d "${pathGit}" ]; then
			        mkdir ${pathGit}
			        if [ -d "${pathGit}" ]; then
		                cd ${pathGit}
		                git init --bare
		                chown -R git:git ${pathGit}
		                echo -e "${green} - - - Création du projet Git${reset}"
	                else
	                    echo -e "${red} - - - Erreur lors de la création du projet Git${reset}"
	                fi
		        fi

		        # Clone du projet GIT
		        # ------------------------------
		        if [ -d "${pathGit}" ]; then
		        	cd /home
		            git clone ${pathGit}
		            echo -e "${green} - - - Clonage du projet Git${reset}"
                fi
                
		        # Premier commit
		        # ------------------------------
                if [ ! -f "${pathHome}/.gitignore" ]; then

echo "# Logs and databases #
######################
*.log
*.cache
.project

# Path #
########
tmp/
cache/
logs/
log/
cache/
.settings/
" > ${pathHome}/.gitignore

		            chown ${user}:${user} ${pathHome}/.gitignore
		            if [ -f "${pathHome}/.gitignore" ]; then
		                cd ${pathHome}
		                git add .
		                git commit -m "Mise en place du site internet"
		                git tag v1.0.0
		                git push --tags origin master
		                echo -e "${green} - - - Premier commit Git${reset}"
		            else
	                    echo -e "${red} - - - Erreur lors du premier commit Git${reset}"
		            fi
		        fi 
		    fi

		    # Création du dossier logs
		    # ------------------------------
		    if [ ! -d "${pathHome}/logs" ]; then
		        mkdir "${pathHome}/logs"
		        if [ "${pathHome}/logs" ]; then
		            echo -e "${green} - - - Création du dossier logs${reset}"
		        else
	                echo -e "${red} - - - Erreur lors de la création du dossier logs${reset}"
		        fi
		    fi
		    
		    # Création du dossier httpdocs
		    # ------------------------------
		    if [ ! -d "${pathHome}/httpdocs" ]; then
		        mkdir "${pathHome}/httpdocs"
		        if [ "${pathHome}/httpdocs" ]; then
		            echo -e "${green} - - - Création du dossier httpdocs${reset}"
		        else
	                echo -e "${red} - - - Erreur lors de la création du dossier httpdocs${reset}"
		        fi
		    fi
		    
		    # Configuration des droits sur les dossiers
		    # ------------------------------
		    chmod 705 ${pathHome}
		    chmod 700 ${pathHome}/httpdocs
		    chmod 600 ${pathHome}/logs
		    chown -R ${user}:${user} ${pathHome}

		    # Création du Vhost
		    # ------------------------------
		    if [ ! -f "/etc/apache2/sites-enabled/${website}" ]; then
		        echo -e "${purple}"
		        a2dissite ${website}
		        echo -e "${reset}"
		    fi

echo "<VirtualHost *:80>
    ServerAdmin contact@${website}
    ServerName www.${website}
    ServerAlias ${website} *.${website}
    DocumentRoot ${pathHome}/httpdocs
    <Directory ${pathHome}/httpdocs>
            Options -Indexes FollowSymLinks MultiViews
            AllowOverride All
    </Directory>
    ErrorLog ${pathHome}/logs/error.log
    LogLevel warn
    CustomLog ${pathHome}/logs/access.log combined
    ServerSignature Off
</VirtualHost>
" > /etc/apache2/sites-available/${website}

	        if [ -f "/etc/apache2/sites-available/${website}" ]; then
		        echo -e "${purple}"
	            a2ensite ${website}
	            service apache2 restart
		        echo -e "${reset}"
	            if [ ! -f "/etc/apache2/sites-enabled/${website}" ]; then
	                echo -e "${green} - - - Activation du site${reset}"
                else
                    echo -e "${red} - - - Erreur lors de l'activation du site${reset}"
                fi		            
	        else
                echo -e "${red} - - - Erreur lors de la configuration du VirtualHost${reset}"
	        fi


	        # Création de la base MySql
	        # ------------------------------
	        echo -en "Créer une base de donnée MySql ? [y/n] "
            read useMysql
	        if [ "${useMysql}" = "y" ]; then
	            echo -en "\nVeuillez saisir le mot de passe qui sera utilisé pour creer la base de donnée : "
                stty -echo
                read password
                stty echo
	            if [ "${password}" ]; then
	                mysql -u root -p -e "create database ${user}; grant usage on *.* to ${user}@localhost identified by '${password}'; grant all privileges on ${user}.* to ${user}@localhost;"
	                echo -e "${green} - - - Création de la base MySql${reset}"
                fi
            fi
            
            cd ${pathHome}
            
            echo -e "${green} - - - ${website} est installé !${reset}"
            
	    else
		    echo -e "${red} - - - Cet utilisateur existe déjà${reset}"
	    fi	    
	else
		echo -e "${red} - - - Veuillez renseigner un nom de domaine${reset}"
	fi
else
	echo -e "${red} - - - Vous devez être en ROOT${reset}"
fi
