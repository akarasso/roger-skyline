VBoxManage createvm --name roger-skyline --ostype "Debian_64" --register
VBoxManage createmedium disk --filename roger-skyline.vdi --size 8000 --variant Fixed
VBoxManage storagectl roger-skyline --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach roger-skyline --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium roger-skyline.vdi
if [ ! -e "debian-9.6.0-amd64-xfce-CD-1.iso" ] ; then
	    curl -C - -L -O https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.6.0-amd64-xfce-CD-1.iso
fi

VBoxManage storagectl roger-skyline --name "IDE Controller" --add ide
VBoxManage storageattach roger-skyline --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $PWD/debian-9.6.0-amd64-xfce-CD-1.iso
VBoxManage modifyvm roger-skyline --ioapic on
VBoxManage modifyvm roger-skyline --boot1 dvd --boot2 disk
VBoxManage modifyvm roger-skyline --memory 4096 --vram 128
VBoxManage modifyvm roger-skyline --nic1 nat
VBoxManage modifyvm roger-skyline --nic2 hostonly --hostonlyadapter2 vboxnet0
VBoxManage modifyvm roger-skyline --natpf1 "guestssh,tcp,127.0.0.1,2222,,22"
VBoxManage startvm test2
