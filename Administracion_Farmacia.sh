#!/bin/bash

# Colores
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Archivos temporales
declare -r tmp_file="/dev/shm/tmp_file"
declare -r tmp_file2="/dev/shm/tmp_file2"
declare -r tmp_file3="/dev/shm/tmp_file3"

# Directorios
backup_dir="/respaldos"
mkdir -p "$backup_dir"
mkdir -p "$backup_dir/extraer"

# Verificación de root
if [[ $EUID -ne 0 ]]; then
  echo -e "${redColour}[!] Este script debe ejecutarse como root.${endColour}"
  exit 1
fi

function menu_usuarios() {
  while true; do
    echo -e "\n${blueColour}--- Administración de Usuarios ---${endColour}"
    echo "1. Alta de usuario"
    echo "2. Baja de usuario"
    echo "3. Consulta de usuario"
    echo "4. Modificación de usuario"
    echo "5. Volver"
    read -p "Seleccione una opción: " opt_u
    case $opt_u in
      1)
        read -p "Nombre del nuevo usuario: " user
        adduser "$user" && echo "Usuario agregado."
        ;;
      2)
        read -p "Usuario a eliminar: " user
        deluser "$user" && echo "Usuario eliminado."
        ;;
      3)
        read -p "Usuario a consultar: " user
        id "$user"
        ;;
      4)
        read -p "Usuario a modificar: " user
        chage -l "$user"
        ;;
      5)
        break
        ;;
      *) echo "Opción inválida.";;
    esac
  done
}

function menu_grupos() {
  while true; do
    echo -e "\n${blueColour}--- Administración de Grupos ---${endColour}"
    echo "1. Alta de grupo"
    echo "2. Baja de grupo"
    echo "3. Consulta de grupo"
    echo "4. Modificación de grupo"
    echo "5. Volver"
    read -p "Seleccione una opción: " opt_g
    case $opt_g in
      1)
        read -p "Nombre del grupo: " grupo
        groupadd "$grupo" && echo "Grupo creado."
        ;;
      2)
        read -p "Grupo a eliminar: " grupo
        groupdel "$grupo" && echo "Grupo eliminado."
        ;;
      3)
        read -p "Grupo a consultar: " grupo
        getent group "$grupo"
        ;;
      4)
        echo "Edite manualmente con vigr o use comandos como gpasswd."
        ;;
      5)
        break
        ;;
      *) echo "Opción inválida.";;
    esac
  done
}

function menu_tareas() {
  echo -e "\n${blueColour}--- Programación de Tareas ---${endColour}"
  echo "1. Cron"
  echo "2. At"
  read -p "Seleccione el método de programación: " tipo
  case $tipo in
    1)
      read -p "Comando a programar: " cmd
      read -p "Minuto (0-59): " min
      read -p "Hora (0-23): " hora
      echo "$min $hora * * * $cmd" >> /etc/crontab
      echo "Tarea añadida a cron."
      ;;
    2)
      read -p "Comando a ejecutar con at: " cmd
      read -p "Hora (por ejemplo, 10:00 AM): " hora
      echo "$cmd" | at "$hora"
      ;;
    *) echo "Opción inválida.";;
  esac
}

function menu_respaldo() {
  echo -e "\n${blueColour}--- Respaldo de Información ---${endColour}"
  echo "1. Local"
  echo "2. A otro servidor (rsync)"
  read -p "Seleccione tipo de respaldo: " tipo
  case $tipo in
    1)
      read -p "Directorio a respaldar: " dir
      tar -czvf "$backup_dir/backup_$(date +%F).tar.gz" "$dir"
      echo "Respaldo local creado."
      ;;
    2)
      read -p "IP destino: " ip
      read -p "Ruta destino: " destino
      read -p "Directorio a respaldar: " dir
      rsync -avz "$dir" "$ip:$destino"
      echo "Respaldo con rsync completado."
      ;;
    *) echo "Opción inválida.";;
  esac
}

function menu_seguridad() {
  echo -e "\n${blueColour}--- Seguridad: Monitoreo ---${endColour}"
  echo "1. Nmap"
  echo "2. Wireshark"
  read -p "Seleccione herramienta: " tipo

  case $tipo in
    1)
      read -p "IP o red objetivo (ej. 192.168.1.0/24): " objetivo
      read -p "¿Desea detección de versiones? (s/n): " version_flag
      read -p "¿Desea escanear un puerto específico? (s/n): " puerto_flag

      opciones="-sS -Pn"
      [[ "$version_flag" =~ ^[sS]$ ]] && opciones+=" -sV"
      if [[ "$puerto_flag" =~ ^[sS]$ ]]; then
        read -p "Puerto a escanear (ej. 22): " puerto
        opciones+=" -p $puerto"
      fi

      read -p "¿Desea guardar los resultados? (s/n): " guardar
      if [[ "$guardar" =~ ^[sS]$ ]]; then
        read -p "Nombre del archivo de salida (sin extensión): " nombre
        archivo="/tmp/${nombre}_nmap.txt"
        comando="nmap $opciones $objetivo > $archivo && echo 'Resultados guardados en $archivo'"
      else
        comando="nmap $opciones $objetivo"
      fi
read -p "¿Desea programar el escaneo? (s/n): " programar
      if [[ "$programar" =~ ^[sS]$ ]]; then
        read -p "¿Será un escaneo recurrente? (s/n): " recurrente
        if [[ "$recurrente" =~ ^[sS]$ ]]; then
          echo "¿Cuándo desea que se ejecute?"
          echo "1. Mañana (todos los días a las 8 AM)"
          echo "2. Noche (todos los días a las 9 PM)"
          echo "3. Personalizar (formato cron)"
          read -p "Opción: " op_recurrente
          case $op_recurrente in
            1)
              echo "0 8 * * * $comando" | crontab -l 2>/dev/null | cat - <(echo) - | crontab -
              echo "Tarea recurrente añadida para las mañanas (8 AM)"
              ;;
            2)
	echo "0 21 * * * $comando" | crontab -l 2>/dev/null | cat - <(echo) - | crontab -
              echo "Tarea recurrente añadida para las noches (9 PM)"
              ;;
            3)
              read -p "Ingrese la expresión cron (ej. 30 14 * * 1-5 para Lunes a Viernes 2:30 PM): " cron_expr
              (crontab -l 2>/dev/null; echo "$cron_expr $comando") | crontab -
              echo "Tarea personalizada añadida."
              ;;
            *) echo "Opción inválida.";;
          esac
        else
          read -p "¿En cuántos minutos desea ejecutar el escaneo? (ej. 5): " minutos
          echo "$comando" | at now + $minutos minutes
          echo "Escaneo programado en $minutos minuto(s)."
        fi
      else
        eval "$comando"
      fi
      ;;
    2)
      echo -e "\nInterfaces disponibles:"
tshark -D
      echo
      read -p "Seleccione el número de la interfaz a usar: " iface_num
      iface=$(tshark -D | grep "^$iface_num\." | cut -d' ' -f2)
      if [[ -z "$iface" ]]; then
        echo "Interfaz inválida."
        return
      fi
      read -p "Duración del escaneo en segundos: " dur
      read -p "Ruta y nombre de archivo de salida (ej. /tmp/captura.pcap): " salida
      timeout "$dur" tshark -i "$iface" -w "$salida"
      echo "Captura almacenada en: $salida"
      ;;
    *)
      echo "Opción inválida."
      ;;
  esac
}

# Menú principal
while true; do
  echo -e "\n${greenColour}--- Sistema de Administración Farmacéutica ---${endColour}"
  echo "1. Administración de Usuarios"
  echo "2. Administración de Grupos"
  echo "3. Programación de Tareas"
  echo "4. Respaldos"
  echo "5. Seguridad"
  echo "6. Salir"
  read -p "Seleccione una opción: " opc
  case $opc in
    1) menu_usuarios;;
    2) menu_grupos;;
    3) menu_tareas;;
    4) menu_respaldo;;
    5) menu_seguridad;;
    6) echo "Saliendo..."; exit 0;;
    *) echo "Opción inválida.";;
  esac
done

