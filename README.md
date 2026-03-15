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
5. **AdGuard Home (Split-Brain DNS):** Servidor DNS local para evitar latencia, resolver dominios localmente y bloquear anuncios/telemetría a nivel de red.

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
│   └── apps-vms/                # Despliegue de Gitea, Jenkins, AdGuard, etc.
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

---

## 5. Diseño de Red y Conectividad

Para maximizar la seguridad en el HP EliteDesk, utilizaremos una arquitectura de **red segmentada**. Esto separa el tráfico de gestión, el tráfico interno y el tráfico expuesto a internet.

### 5.1. Segmentación de Puentes (Proxmox Bridges)

En lugar de un solo `vmbr0`, definiremos áreas lógicas para aislar servicios:

| Puente (Bridge) | Nombre Lógico | Propósito | Seguridad |
| --- | --- | --- | --- |
| **vmbr0** | **Management** | Acceso a Proxmox UI, SSH del Host. | Solo LAN Local y Tailscale. |
| **vmbr1** | **DMZ (Public)** | Cloudflared y Traefik. | Única zona que toca internet (vía Túnel). |
| **vmbr2** | **Trusted Apps** | AdGuard, Gitea, Jenkins, Bases de Datos. | Sin acceso directo desde internet. |

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

### 5.3. Resolución de Nombres (Split-Brain DNS) y Prevención de Hairpinning

Para que `servicio.lucaspintos.link` funcione a máxima velocidad dentro de tu casa y sin depender exclusivamente de internet, implementamos una estrategia para evitar el "Efecto Boomerang" (salir a internet para volver a entrar a tu propia red local):

* **DNS Externo (Cloudflare):** Apunta los CNAMEs al ID de tu Túnel para conexiones desde el exterior.
* **DNS Interno (AdGuard Home):** Instalado en una VM dentro de `vmbr2`.
  * **DNS Rewrite:** Intercepta cualquier petición a `*.lucaspintos.link` desde tu red Wi-Fi y responde directamente con la IP privada de **Traefik** (`10.0.0.10`).
  * **Beneficios:** El tráfico interno viaja por la LAN (cero latencia), los servicios siguen funcionando aunque se corte el internet de Antel, y se bloquean anuncios y rastreadores en todos los dispositivos de la casa.

### 5.4. Lógica de Enrutamiento y Proveedores

Traefik actuará como el "Inspector de Tráfico" centralizado, utilizando un modelo de **doble proveedor** para descubrir servicios en todo el HP EliteDesk:

#### A. Proveedores de Configuración

1. **Docker Provider (Automático):** Para contenedores que corren en la misma VM que Traefik. Se gestiona mediante `labels` en los archivos `docker-compose.yml`.
2. **File Provider (Dinámico):** Para servicios que viven fuera de la VM de Traefik (otras VMs de Proxmox o AdGuard). Traefik monitorea una carpeta (ej: `./dynamic/`) y aplica cambios en tiempo real sin reiniciar.

#### B. Clasificación de Servicios y Seguridad (Middlewares)

Utilizaremos **Middlewares de IP White-listing** para segmentar quién puede ver qué:

| Categoría | Proveedor Típico | Middleware de Acceso | Regla de Red |
| --- | --- | --- | --- |
| **Servicios Públicos** | Docker | **Ninguno / Cloudflare WAF** | Accesibles vía `cloudflare-tunnel`. |
| **Servicios Privados** | File / Docker | **`internal-whitelist`** | Solo IPs de Tailscale (`100.64.0.0/10`) y LAN Local. |

#### C. Lógica de Respuesta

* **Si el tráfico viene de Internet:** Cloudflare Tunnel lo entrega a Traefik. Si el servicio tiene el middleware `internal-whitelist`, Traefik responde con un **403 Forbidden**.
* **Si el tráfico viene de Tailscale/LAN:** Traefik valida la IP, acepta el middleware y entrega el tráfico al servicio correspondiente, sin importar en qué VM se encuentre.

---

# 🗺️ Roadmap Integrado: Proxmox GitOps & Networking

## Fase 1: Cimientos y Segmentación de Red (El Hipervisor)

*Antes de crear cualquier VM, hay que preparar el terreno físico y lógico.*

1. **BIOS & Proxmox:** Habilitar virtualización (VT-x), instalar Proxmox VE 8.x.
2. **Configuración de Red (Bridges):** Crear en Proxmox (`System > Network`):
   * `vmbr0` (Management/DMZ externo).
   * `vmbr1` (Public/Proyectos).
   * `vmbr2` (Internal/Herramientas).
3. **API Access:** Crear el API Token para que Packer y Terraform actúen.
4. **Tailscale en el Host:** Instalar Tailscale en Proxmox como acceso de emergencia.

## Fase 2: La Fábrica de Imágenes (Packer)

*Crear los moldes para tus servidores.*

1. **Setup de Packer:** Definir el `ubuntu.pkr.hcl` e inyectar llaves SSH vía `.pkrvars`.
2. **Primer Template:** Ejecutar el build instalando `qemu-guest-agent` y `cloud-init` para automatizar la configuración del SO.

## Fase 3: Orquestación de Red e Infra (Terraform)

*Aplicar la arquitectura de segmentación y levantar infraestructura base.*

1. **Módulos de Red en Terraform:** Desplegar VMs y conectarlas a las redes correctas.
   * **VM de Edge (Traefik):** Conectada a las 3 redes para ruteo interno.
   * **VMs de Herramientas/Apps:** Conectadas únicamente a sus respectivas subredes.
2. **Infraestructura Core:** Desplegar la VM para **AdGuard Home** en la red interna (`vmbr2`).

## Fase 4: El "Gatekeeper", Edge y DNS (Traefik + Cloudflare + AdGuard)

*Hacer que lucaspintos.link cobre vida de forma optimizada.*

1. **Split-Brain DNS:** Configurar AdGuard Home. Establecer las reescrituras DNS ("DNS Rewrites") para apuntar tu dominio a la IP de Traefik (`10.0.0.10`). Configurar el DHCP de tu router para repartir la IP de AdGuard a tus dispositivos.
2. **Despliegue de Traefik:** En la VM de Edge, levantar Traefik con Docker vía Ansible.
3. **Cloudflare Tunnel:** Levantar el conector (en la misma VM que Traefik) apuntando al puerto 80 local. Configurar los CNAMEs públicos en Cloudflare.

## Fase 5: GitOps y Seguridad Zero Trust

*Automatización total y blindaje final.*

1. **Middlewares de Traefik:** Crear middleware de **IP Whitelist** para limitar accesos administrativos solo a LAN/Tailscale.
2. **Cloudflare Access:** Proteger subdominios sensibles con autenticación (Ej. Google/GitHub).
3. **Pipeline CI/CD:** Automatizar Ansible y Terraform para aplicar cambios de infraestructura al hacer push al repositorio `homelab-infra`.