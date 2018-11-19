VBoxManage createvm --name test2 --ostype "Debian_64" --register
VBoxManage createmedium disk --filename test2.vdi --size 8000 --variant Fixed
VBoxManage storagectl test2 --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach test2 --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium test2.vdi
if [ ! -e "debian-9.6.0-amd64-xfce-CD-1.iso" ] ; then
	    curl -C - -L -O https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.6.0-amd64-xfce-CD-1.iso
fi

VBoxManage storagectl test2 --name "IDE Controller" --add ide
VBoxManage storageattach test2 --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $PWD/debian-9.6.0-amd64-xfce-CD-1.iso
VBoxManage modifyvm test2 --ioapic on
VBoxManage modifyvm test2 --boot1 dvd --boot2 disk
VBoxManage modifyvm test2 --memory 4096 --vram 128
VBoxManage modifyvm test2 --nic1 nat
VBoxManage modifyvm test2 --nic2 hostonly --hostonlyadapter2 vboxnet0
VBoxManage modifyvm test2 --natpf1 "guestssh,tcp,127.0.0.1,2222,,22"
VBoxManage startvm test2
