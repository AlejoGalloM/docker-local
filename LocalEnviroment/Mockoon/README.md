# Carpeta con la utilidad Mockoon para simular SUA.

## Opciones de Ejecución

1. Instalando la herramienta [Mockoon](https://mockoon.com/#download).

   - Una vez instalado importar el archivo `SUA.json`
    
2. Usando npm para instalar `mockoon-cli`

   - Instalar depedencias:  

     `npm run install`

   - Ejectutar el mock:
   
     `npm run start`
     
     Para inicia el servicio de mock por el puerto **3000** y cargar la configuracion del archivo `SUA.json`.

   - Detener el mock:
   
     `npm run stop`.

3. Usando docker.

   `mockoon-cli` permite crear un archivo Dockerfile para construir una imagen docker.
   
   En el momento ya existe un archivo Dockerfile creado.

   Pero si necesita recrear el dockerfile:

   `npm run dockerize`

   Este archivo se puede usar con docker compose para armar un contenedor:

   ```yaml
    suamock:
        build: ./mockoon
        ports:
        - "3000:3000"
   ```

