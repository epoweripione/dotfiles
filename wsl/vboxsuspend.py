# A script to suspend all running VirtualBox VMs

# How to use:
# Download and install Python 2.7.x from python.org
# Create the python script file somewhere on your system using Notepad or any other plain text editor (see below)
# Open Task Scheduler
# Choose Action -> Create a Basic Task... and use the wizard to create a task with the following settings
# A name of your choice
# Start the task when a specific event is logged
# Log: System
# Source: Winlogon
# Event ID: 7002
# Start a Program
# Next to Program/Script, enter the full path to your python.exe, for instance c:\Python27\python.exe
# Next to Add arguments, enter the full path where you put the python script file, for instance I put mine in a subfolder of my documents folder, so this is C:\Users\rakslice\Documents\vboxsuspend\vboxsuspend.py
# Choose Finish.
# Now VirtualBox VMs should be suspended on logout/restart/shutdown.

import os

import subprocess

import sys


class VM(object):
    def __init__(self, name, uuid):
        self.name = name
        self.uuid = uuid

    def __repr__(self):
        return "VM(%r,%r)" % (self.name, self.uuid)


class VBoxRunner(object):
    def __init__(self):
        program_files = os.environ["ProgramW6432"]
        vbox_dir = os.path.join(program_files, "Oracle", "VirtualBox")
        self.vboxmanage_filename = os.path.join(vbox_dir, "VBoxManage.exe")

    def vbox_run(self, *args):
        subprocess.check_call([self.vboxmanage_filename] + list(args))

    def vbox_run_output(self, *args):
        return subprocess.check_output([self.vboxmanage_filename] + list(args))

    def list(self, running=True):
        if running:
            list_cmd = "runningvms"
        else:
            list_cmd = "vms"

        return [self.parse_vm_list_entry(x) for x in self.vbox_run_output("list", list_cmd).strip().split("\n")]

    def suspend_all(self):
        success = True
        stopped_some_vms = False
        vms = self.list(running=True)
        for vm in vms:
            if vm is None:
                continue
            # noinspection PyBroadException
            try:
                self.suspend_vm(vm)
            except:
                success = False
            else:
                stopped_some_vms = True
        if not stopped_some_vms:
            self.message("No running vms")
        return success

    @staticmethod
    def parse_vm_list_entry(x):
        """:type x: str"""
        if not x.startswith('"'):
            return None
        end_pos = x.find('"', 1)
        if end_pos == -1:
            return None
        name = x[1:end_pos]
        assert x[end_pos + 1: end_pos + 3] == " {"
        assert x.endswith("}")
        uuid = x[end_pos + 2:]

        return VM(name, uuid)

    @staticmethod
    def message(msg):
        print >>sys.stderr, msg

    def suspend_vm(self, vm):
        assert isinstance(vm, VM)
        self.vbox_run("controlvm", vm.uuid, "savestate")


def main():
    vr = VBoxRunner()
    success = vr.suspend_all()
    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()