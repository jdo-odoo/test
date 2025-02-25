Voici un fichier de configuration complet que vous pouvez importer dans votre routeur MikroTik. Il configure deux Wi-Fi distincts (`WiFi-Adultes` et `WiFi-Enfants`), applique des VLANs, des règles de pare-feu, un filtrage DNS, une planification des horaires d’accès et une limitation de bande passante.  

### **📌 Instructions :**
1. **Copiez ce fichier dans un éditeur de texte** et enregistrez-le sous `mikrotik_wifi_config.rsc`.
2. **Importez-le dans MikroTik** via **Winbox** ou en ligne de commande :
   ```bash
   /import file=mikrotik_wifi_config.rsc
   ```

---

### **📄 Fichier de configuration (`mikrotik_wifi_config.rsc`)**


Ce fichier configure :  
✅ **Deux SSID distincts** (`WiFi-Adultes` et `WiFi-Enfants`)  
✅ **Deux VLANs séparés** (`20` pour adultes, `30` pour enfants)  
✅ **Filtrage de sites Web pour WiFi-Enfants**  
✅ **Restrictions horaires d’accès (07h-21h)**  
✅ **Limitation de débit à 2 Mbps pour WiFi-Enfants**  

🚀 **Importez le fichier et testez !** Besoin d’ajustements ? 😊

------------------------------------

Explication détaillée

Excellente idée ! Vous pouvez configurer un **Wi-Fi séparé** pour les enfants avec des restrictions (ex: blocage de sites, limitation de vitesse, horaires d’accès), tout en gardant un **Wi-Fi adultes** avec un accès libre.  

---

## **📌 Plan de configuration**
Nous allons :
1. **Créer deux réseaux Wi-Fi** :  
   - `WiFi-Enfants` → Avec restrictions  
   - `WiFi-Adultes` → Sans restriction  
2. **Attribuer des sous-réseaux distincts** avec VLANs  
3. **Appliquer des restrictions pour le WiFi-Enfants**  
   - Blocage de sites Web  
   - Filtrage des applications  
   - Limitation d’horaires et de débit  

---

## **1️⃣ Création de deux réseaux Wi-Fi séparés**
Nous allons créer deux SSID sur l'interface sans fil du MikroTik.

### **🔹 Ajout des interfaces Wi-Fi**
1. **Créer le Wi-Fi Adultes** (SSID : `WiFi-Adultes`)  
   ```bash
   /interface wireless set wlan1 ssid="WiFi-Adultes" mode=ap-bridge
   ```

2. **Créer le Wi-Fi Enfants** (SSID : `WiFi-Enfants`)  
   ```bash
   /interface wireless add name=wlan2 master-interface=wlan1 ssid="WiFi-Enfants" mode=ap-bridge
   ```

---

## **2️⃣ Séparer les réseaux avec VLANs**
Nous allons attribuer un **VLAN différent** à chaque Wi-Fi :
- **VLAN 20** → WiFi-Adultes : 192.168.20.0/24  
- **VLAN 30** → WiFi-Enfants : 192.168.30.0/24  

### **🔹 Configuration des VLANs**
1. **Créer les VLANs**  
   ```bash
   /interface vlan add name=vlan20 vlan-id=20 interface=bridge
   /interface vlan add name=vlan30 vlan-id=30 interface=bridge
   ```

2. **Attribuer les VLANs aux réseaux Wi-Fi**  
   ```bash
   /interface wireless set wlan1 vlan-id=20 vlan-mode=use-tag
   /interface wireless set wlan2 vlan-id=30 vlan-mode=use-tag
   ```

3. **Créer des sous-réseaux pour chaque VLAN**  
   ```bash
   /ip address add address=192.168.20.1/24 interface=vlan20
   /ip address add address=192.168.30.1/24 interface=vlan30
   ```

4. **Configurer le DHCP pour chaque VLAN**  
   ```bash
   /ip dhcp-server add name=dhcp-adultes interface=vlan20 address-pool=pool20
   /ip dhcp-server add name=dhcp-enfants interface=vlan30 address-pool=pool30

   /ip pool add name=pool20 ranges=192.168.20.10-192.168.20.200
   /ip pool add name=pool30 ranges=192.168.30.10-192.168.30.200

   /ip dhcp-server network add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8,1.1.1.1
   /ip dhcp-server network add address=192.168.30.0/24 gateway=192.168.30.1 dns-server=8.8.8.8,1.1.1.1
   ```

---

## **3️⃣ Appliquer des restrictions sur WiFi-Enfants**
Nous allons maintenant appliquer des **règles spécifiques au WiFi-Enfants**.

### **🔹 Blocage des sites Web**
Pour bloquer des sites comme **Facebook, YouTube, TikTok**, on utilise le **DNS du routeur**.

```bash
/ip dns static add name=facebook.com address=127.0.0.1
/ip dns static add name=youtube.com address=127.0.0.1
/ip dns static add name=tiktok.com address=127.0.0.1
```

OU si vous préférez un **firewall plus strict**, bloquez leurs adresses IP :
```bash
/ip firewall address-list add list=blocked_sites address=157.240.221.35 comment="Facebook"
/ip firewall address-list add list=blocked_sites address=142.250.190.46 comment="YouTube"
/ip firewall filter add chain=forward src-address=192.168.30.0/24 dst-address-list=blocked_sites action=drop
```

---

### **🔹 Restriction des horaires d’accès**
Si vous voulez **autoriser Internet uniquement de 07h à 21h** sur `WiFi-Enfants`, utilisez le **Scheduler**.

1. **Créer une règle pour autoriser le trafic**  
   ```bash
   /ip firewall filter add chain=forward src-address=192.168.30.0/24 action=accept comment="WiFi-Enfants OK"
   ```

2. **Créer un script pour bloquer l’accès à 21h**  
   ```bash
   /system script add name=block_enfants source="/ip firewall filter remove [find comment='WiFi-Enfants OK']"
   ```

3. **Créer un script pour autoriser l’accès à 07h**  
   ```bash
   /system script add name=allow_enfants source="/ip firewall filter add chain=forward src-address=192.168.30.0/24 action=accept comment='WiFi-Enfants OK'"
   ```

4. **Créer une tâche planifiée**  
   ```bash
   /system scheduler add name=fermeture_enfants start-time=21:00 interval=1d on-event=block_enfants
   /system scheduler add name=ouverture_enfants start-time=07:00 interval=1d on-event=allow_enfants
   ```

---

### **🔹 Limitation de vitesse pour le WiFi-Enfants**
Si vous voulez **limiter la bande passante à 2 Mbps max**, utilisez une **queue simple** :

```bash
/queue simple add name="WiFi-Enfants Limit" target=192.168.30.0/24 max-limit=2M/2M
```

---

## **4️⃣ Vérification et test**
1. **Connectez-vous au WiFi-Enfants et essayez d’accéder aux sites bloqués** 🛑  
2. **Testez Internet après 21h sur le WiFi-Enfants** : il doit être coupé ⏳  
3. **Vérifiez que le WiFi-Adultes fonctionne sans restriction** ✅  

---

## **✅ Conclusion**
Nous avons maintenant :
🎯 **Deux Wi-Fi distincts** avec VLANs  
🛑 **Un WiFi-Enfants restreint** (sites bloqués, limitation de vitesse, horaires)  
✅ **Un WiFi-Adultes sans restrictions**  

👉 **Besoin d’une amélioration ?** 😊
