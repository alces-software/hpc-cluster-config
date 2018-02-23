yum -y install nfs-utils

<% if (plugins.nfs.config.nfs_isserver rescue false) -%>
# Create export directories
<% plugins.nfs.config.nfs_exports.each do | path, opts | -%>
mkdir -p <%= path %>
<% end -%>

# Increase nfsd thread count
sed -ie "s/^#\RPCNFSDCOUNT.*$/\RPCNFSDCOUNT=32/g" /etc/sysconfig/nfs

EXPORTOPTS="<%= config.networks.pri.network %>/<%= config.networks.pri.netmask %>(rw,no_root_squash,sync)"

EXPORTS=`cat << EOF
<% plugin.nfs.config.nfs_exports.each do | path, opts | -%>
<%= path %>   <%= if defined?(opts.options) then opts.options else "#{config.networks.pri.network}/#{config.networks.pri.netmask}(rw,no_root_squash,sync)" end %>
<% end -%>
EOF`

echo "$EXPORTS" > /etc/exports

<% elsif (!plugin.nis.config.nis_isserver rescue true) -%>

MOUNTS=`cat << EOF
<% plugin.nfs.answer.nfs_mounts.each do | mount, path | -%>
<%= path.server %>:<%= path.export %>    <%= mount %>    nfs    <%= if defined?(path.options) then path.options else 'intr,rsize=32768,wsize=32768,vers=3,_netdev' end -%>    0 0
<% end -%>
EOF`

echo "$MOUNTS" >> /etc/fstab

<% plugin.nfs.answer.nfs_mounts.each do | mount, path | -%>
mkdir -p <%= path.target %>
<% end -%>

<% end -%>

systemctl enable nfs
systemctl restart nfs
