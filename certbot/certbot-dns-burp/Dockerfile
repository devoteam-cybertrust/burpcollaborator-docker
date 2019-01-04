FROM certbot/certbot

COPY . src/certbot-dns-cloudflare

RUN pip install --no-cache-dir --editable src/certbot-dns-cloudflare

# INSTALL DNSMASQ
RUN apk add dnsmasq
RUN echo 'conf-dir=/etc/dnsmasq.d/,*.conf' > /etc/dnsmasq.conf
RUN echo "user=root" >> /etc/dnsmasq.conf
