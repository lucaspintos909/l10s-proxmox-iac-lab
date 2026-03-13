# 🚀 Blueprint: Home Lab GitOps (lucaspintos.link)

## 1. Visión General de la Arquitectura

El objetivo es gestionar un servidor **HP EliteDesk (i5-9th Gen, 32GB RAM)** de forma totalmente automatizada, eliminando la configuración manual en la interfaz de Proxmox.

### Flujo de Tráfico y Acceso

| Tipo de Acceso | Ruta de Conexión | Seguridad |
| --- | --- | --- |
| **Público** | Internet → Cloudflare Tunnel → Traefik → App | Cloudflare WAF + Traefik Middlewares |
| **Privado** | Tailscale (VPN) → IP Interna → Traefik → App | Encriptación de punto a punto (Node-to-Node) |
| **Gestión** | LAN local / Tailscale → IP Directa Host | Sin exposición externa |

---

## 2. El Stack Tecnológico (IaC & GitOps)

Para que tu infraestructura sea reproducible, usamos este "pipeline" lógico:

1. **Packer (The Builder):** Crea plantillas (Templates) de Ubuntu/Debian en Proxmox con `qemu-guest-agent` y `cloud-init` preinstalados.
2. **Terraform/OpenTofu (The Orchestrator):** Despliega las VMs y Contenedores basándose en las plantillas de Packer. Define CPU, RAM y Red.
3. **Traefik (The Gatekeeper):** Reverse Proxy que recibe todo el tráfico y lo distribuye mediante subdominios (ej: `gitea.lucaspintos.link`).
4. **Cloudflare Tunnel:** El "puente" que conecta tu casa con el dominio sin abrir puertos en el router.

---

## 3. Estructura Sugerida del Repositorio (`homelab-infra`)

Copia esta estructura para organizar tus archivos de configuración:

```text
/homelab-infra
├── packer/
│   ├── ubuntu-24-04/
│   │   ├── ubuntu.pkr.hcl       # Configuración de la imagen
│   │   ├── http/user-data       # Autoinstall de Ubuntu
│   │   └── secrets.pkrvars.hcl  # LLAVES SSH (IGNORAR EN GIT)
├── terraform/
│   ├── modules/                 # Módulos reutilizables para crear VMs
│   ├── network-vm/              # Despliegue de la VM de Traefik
│   └── apps-vms/                # Despliegue de Gitea, Jenkins, etc.
├── ansible/                     # Playbooks para configurar software dentro de las VMs
├── compose/                     # Archivos Docker Compose (Traefik, Cloudflared)
├── .gitignore                   # Para no subir secretos (*.tfvars, *.pkrvars)
└── README.md                    # Esta documentación

```

---

## 4. Mejores Prácticas Implementadas

* **Zero-Trust:** Uso de **Cloudflare Access** para servicios sensibles. Solo tú puedes entrar tras autenticarte con tu email/GitHub.
* **Invisible Network:** No hay redirección de puertos (Port Forwarding). Tu IP pública de casa permanece oculta.
* **Immutable Infrastructure:** Si una VM falla, no se repara; se destruye y se recrea con Terraform en segundos.
* **Secrets Management:** Uso de archivos `.tfvars` y `.pkrvars` locales (fuera de Git) para manejar claves de API y SSH.

¡Excelente idea! La red es la columna vertebral de tu home lab. Una buena segmentación no solo es más profesional, sino que evita que un problema en un servicio expuesto (como un sitio web) comprometa a todo tu servidor Proxmox.

Aquí tienes la sección de **Redes y Conectividad** lista para añadir a tu documentación:

---

## 5. Diseño de Red y Conectividad

Para maximizar la seguridad en el HP EliteDesk, utilizaremos una arquitectura de **red segmentada**. Esto separa el tráfico de gestión, el tráfico interno y el tráfico expuesto a internet.

### 5.1. Segmentación de Puentes (Proxmox Bridges)

En lugar de un solo `vmbr0`, definiremos áreas lógicas para aislar servicios:

| Puente (Bridge) | Nombre Lógico | Propósito | Seguridad |
| --- | --- | --- | --- |
| **vmbr0** | **Management** | Acceso a Proxmox UI, SSH del Host. | Solo LAN Local y Tailscale. |
| **vmbr1** | **DMZ (Public)** | Cloudflared y Traefik. | Única zona que toca internet (vía Túnel). |
| **vmbr2** | **Trusted Apps** | Gitea, Jenkins, Bases de Datos. | Sin acceso directo desde internet. |

### 5.2. Estrategia de Acceso "Zero Open Ports"

Esta arquitectura elimina la necesidad de abrir puertos en tu router (Port Forwarding), ocultando tu IP pública residencial.

1. **Ingreso Público (Cloudflare Tunnel):**
* El tráfico llega a `*.lucaspintos.link`.
* El túnel lo entrega al contenedor `cloudflared` en la DMZ.
* `cloudflared` lo pasa a **Traefik**.


2. **Ingreso Privado (Tailscale):**
* Acceso total a la red `100.x.x.x` de Tailscale.
* Permite administrar Proxmox y acceder a servicios internos sin pasar por Cloudflare.
* **Best Practice:** Configurar el EliteDesk como *Exit Node* para navegar seguro desde redes públicas.



### 5.3. Resolución de Nombres (Split-Brain DNS)

Para que `servicio.lucaspintos.link` funcione tanto dentro como fuera de tu casa sin errores:

* **DNS Externo (Cloudflare):** Apunta los CNAMEs al ID de tu Túnel.
* **DNS Interno (Pi-hole / AdGuard Home):** * Instalado en una VM de Proxmox.
* Crea un "DNS Rewrite" para que `*.lucaspintos.link` resuelva directamente a la IP privada de **Traefik**.
* *Beneficio:* El tráfico interno nunca sale a internet, mejorando la velocidad y la latencia.



¡Excelente! Integrar el **File Provider** es lo que le da "superpoderes" a tu Traefik, permitiéndole ver más allá de su propia VM y gestionar todo tu ecosistema de Proxmox.

Aquí tienes la actualización para la sección 5.4 de tu documentación, reflejando esta arquitectura híbrida (Docker + File Provider):

---

### 5.4. Lógica de Enrutamiento y Proveedores

Traefik actuará como el "Inspector de Tráfico" centralizado, utilizando un modelo de **doble proveedor** para descubrir servicios en todo el HP EliteDesk:

#### A. Proveedores de Configuración

1. **Docker Provider (Automático):** Para contenedores que corren en la misma VM que Traefik. Se gestiona mediante `labels` en los archivos `docker-compose.yml`.
2. **File Provider (Dinámico):** Para servicios que viven fuera de la VM de Traefik (otras VMs de Proxmox, contenedores en otros hosts o la propia interfaz de Proxmox). Traefik monitorea una carpeta (ej: `./dynamic/`) y aplica cambios en tiempo real sin reiniciar.

#### B. Clasificación de Servicios y Seguridad (Middlewares)

Utilizaremos **Middlewares de IP White-listing** para segmentar quién puede ver qué:

| Categoría | Proveedor Típico | Middleware de Acceso | Regla de Red |
| --- | --- | --- | --- |
| **Servicios Públicos** | Docker | **Ninguno / Cloudflare WAF** | Accesibles vía `cloudflare-tunnel`. |
| **Servicios Privados** | File / Docker | **`internal-whitelist`** | Solo IPs de Tailscale (`100.64.0.0/10`) y LAN Local. |

#### C. Ejemplo de Implementación (File Provider)

Para servicios en otras VMs, definiremos archivos YAML descriptivos. Esto permite que servicios como la UI de Proxmox tengan SSL de confianza

#### D. Lógica de Respuesta

* **Si el tráfico viene de Internet:** Cloudflare Tunnel lo entrega a Traefik. Si el servicio tiene el middleware `internal-whitelist`, Traefik responde con un **403 Forbidden**.
* **Si el tráfico viene de Tailscale/LAN:** Traefik valida la IP, acepta el middleware y entrega el tráfico al servicio correspondiente, sin importar en qué VM se encuentre.


# 🗺️ Roadmap Integrado: Proxmox GitOps & Networking

## Fase 1: Cimientos y Segmentación de Red (El Hipervisor)

*Antes de crear cualquier VM, hay que preparar el terreno físico y lógico.*

1. **BIOS & Proxmox:** Habilitar virtualización (VT-x), instalar Proxmox VE 8.x.
2. **Configuración de Red (Bridges):** Desde la interfaz de Proxmox (`System > Network`), crear:
* `vmbr0` (Management): Ya viene por defecto. IP del host aquí.
* `vmbr1` (DMZ/Public): Sin IP en el host. Para Traefik y Cloudflared.
* `vmbr2` (Internal): Sin IP en el host. Para tus bases de datos y servicios privados.


3. **API Access:** Crear el API Token para que Packer y Terraform "tengan las llaves" del servidor.
4. **Tailscale en el Host:** Instalar Tailscale en Proxmox como acceso de emergencia.

## Fase 2: La Fábrica de Imágenes (Packer)

*Crear los moldes para tus servidores.*

1. **Setup de Packer:** Instalar en tu laptop.
2. **Definición de Imagen:** Crear el `ubuntu.pkr.hcl` configurando el `ssh_public_key` mediante variables para no exponerla.
3. **Primer Template:** Ejecutar el build. Esta imagen debe incluir el `qemu-guest-agent` para que Proxmox pueda ver la IP de la VM.

## Fase 3: Orquestación de Red e Infra (Terraform)

*Empezamos a aplicar la arquitectura de segmentación.*

1. **Módulos de Red en Terraform:** Definir las VMs asignándoles el puente correspondiente según su función:
* **VM de Gestión:** Conectada a `vmbr1` (para recibir tráfico) y `vmbr2` (para hablar con las apps).
* **VMs de Apps:** Conectadas únicamente a `vmbr2`.


2. **Cloud-Init:** Usar Terraform para pasarle la configuración de red estática a cada VM basándose en tu plan de direccionamiento.

## Fase 4: El "Gatekeeper" y Edge (Traefik + Cloudflare)

*Hacer que lucaspintos.link cobre vida.*

1. **Despliegue de Traefik:** En la VM de gestión (DMZ), levantar Traefik con Docker.
2. **Configuración de Entrypoints:** * `web` (Puerto 80) y `websecure` (Puerto 443).
* Configurar **Certificados Wildcard** vía DNS Challenge con Cloudflare.


3. **Cloudflare Tunnel:** Levantar el conector que apunte directamente a la IP de Traefik.
4. **Split-Brain DNS:** Instalar **Pi-hole o AdGuard Home** en una VM interna. Configurar las "DNS Rewrites" para que dentro de tu casa `*.lucaspintos.link` resuelva a la IP local de Traefik, evitando latencia de internet.

## Fase 5: GitOps y Seguridad Zero Trust

*Automatización total y blindaje.*

1. **Middlewares de Traefik:** * Crear un middleware de **IP Whitelist** que solo permita acceso a los servicios internos si la IP viene de Tailscale o de tu red local.
2. **Cloudflare Access:** Proteger subdominios sensibles con autenticación (GitHub/Google).
3. **Pipeline CI/CD:** Configurar que al subir cambios a tu repo `homelab-infra`, Terraform se ejecute automáticamente y actualice las VMs o las reglas de red.

