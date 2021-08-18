# CCB Analytic Workbench
This document describes the intended use of the CCB Analytic Workbench Docker image.  The container is preconfigured with R and Python and supporting packages, and is intended to serve as a base configuration for CCB's interactive analytic workbench.  It is preconfigured with RStudio Server, which runs at startup, along with an SSH server.  X11 is supported for graphical applications.  Microsoft SQL Server is also included, and can be optionally run at startup (see below).

# Table of Contents

1. [Starting the Container](#Starting-the-Container)
2. [Connecting to the Container](#Connecting-to-the-Container)
3. [Other Information](#Other-Information)

# Starting the Container

To pull the image from DockerHub and run the container:

```bash
docker \
    run \
        --rm \
        --name workbench \
        -d \
        -v /SOME_LOCAL_PATH:/HostData \
        -p 8787:8787 \
        -p 2200:22 \
        -p 1433:1433 \
        -e 'CONTAINER_USER_USERNAME=user' \
        -e 'CONTAINER_USER_PASSWORD=password' \
        -e 'ACCEPT_EULA=Y' \
        -e 'SA_PASSWORD=yourStrong(!)Password' \
        hmsccb/analytic-workbench:version-1.2.1
```

Alternatively, clone the Git repository and:

```bash
docker build --progress=plain --tag hmsccb/analyticworkbench:development .

docker \
    run \
        --rm \
        --name workbench \
        -d \
        -v /SOME_LOCAL_PATH:/HostData \
        -p 8787:8787 \
        -p 2200:22 \
        -p 1433:1433 \
        -e 'CONTAINER_USER_USERNAME=user' \
        -e 'CONTAINER_USER_PASSWORD=password' \
        -e 'ACCEPT_EULA=Y' \
        -e 'SA_PASSWORD=yourStrong(!)Password' \
        hmsccb/analytic-workbench:development
```


## Parameters

### Bind Mount Volume /SOME_LOCAL_PATH

/SOME_LOCAL_PATH should be replaced by the path to the directory on the host that you would like to make available in the running container. Inside the container, this directory on the host will be mounted at /HostData. If there is no need to make host data available in the continer this argument can be omitted.

### Environment Variables CONTAINER_USER_USERNAME and CONTAINER_USER_PASSWORD

These are the username and password that will get created on the container, and will be used to connect to it via ssh, or to log into the R Studio Server Web UI.

### Environment Variables ACCEPT_EULA and SA_PASSWORD

This image is built on top of Microsoft's official container image for SQL Server on Linux. These arguments control configuration of the SQL Server instance. In order to start an instance of SQL Server in the container, ACCEPT_EULA must be set to "Y" and SA_PASSWORD must be set to a password of your choosing for the SQL Server 'sa' account meeting minimum complexity requirements.  See https://hub.docker.com/_/microsoft-mssql-server for details.  If either of these conditions is not met, the container will run, but the SQL Server process will not start.

### Port Mapping

The ``-p`` flag to Docker maps a TCP port in the container to a TCP port on the Docker host.  More information is available [here](https://docs.docker.com/config/containers/container-networking/).  For example, in the above invocation, we are mapping TCP 8787 in the container to TCP 8787 on the Docker host, and TCP 22 (ssh) in the container to TCP 2200 on the Docker host.  This allows the user to connect to the container by ssh'ing to ``localhost`` on port 2200, or aiming a web browser at port 8787 on ``localhost`` to connect to R Studio Server.  More information is available in [Connecting to the Container](#3.-Connecting-to-the-Container).  TCP 1433 in the container is being mapped to TCP 1433 on the Docker host to allow connectivity to SQL Server.

### Mounting Network Shares

In order to mount a network share (e.g. SMB) from within the container, the container needs to be run with the --privileged flag.  This is a security vulnerability.  Make sure you understand the implications before doing such.


# Connecting to the Container

When the container is run with the command described in 
[Starting the Container](#Starting-the-Container), both an SSH server and an R Studio Server instance are started inside the container.
You have three options for how you will interact with an R session running in the container.  You can:

1. Use a secure shell (SSH) client to connect to the container and run R on the command line
2. Use a web browser to connect to R Studio Server running in the container
3. Run the container interactively and run R on the command line directly, without an SSH client

These options, along with slight variations, are described in the following sections.

## 1. Connecting via SSH
If you are connecting to the container via ssh, you will need an SSH client. Linux and macOS typically have a command line ssh client installed out of the box. For Windows systems you will need to download an SSH client such as PuTTY (https://www.putty.org/).

To connect via ssh you'll use the following command, which assumes the default user/password:

```bash
ssh dockeruser@HOST_ADDRESS -p 2200
```

where ``HOST_ADDRESS`` is the IP address of the Docker host.  Recall that we are mapping the ports that the SSH server and R Studio Server
are using from the container to the Docker host.  If you are running the ssh command on the same host where Docker is running, you 
can substitute ``localhost`` for HOST_ADDRESS.  If you are ssh'ing to the container from another host (e.g., running Docker on a server, connecting from a workstation/laptop), then you will need to substitute the IP address of the Docker host for ``HOST_ADDRESS``.  In this latter case, you will also need to ensure that any relevant firewalls allow connections on TCP port 2200 from the "workstation" to the "server".  A full discussion of the principals of firewall configuration are beyond the scope of this document.  For further assistance, you may need to consult your local information technology team.

Once you have successfully established an SSH connection to the container, you can run an R command-line session.  

If you have previously run another version of the container on the same host, you may receive a message like the following
when SSH attempts to connect:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

The SSH client keeps a record of host identifiers associated with IP addresses.  As the version of the container changes, 
the host identifier may change as well, causing the SSH client to raise the warning to alert the user to the fact that 
they are connecting to a different host than they had previously at this network address.  

You will need to either manually remove the old host association with the IP address (e.g., by deleting the entry from the client's
``~/.ssh/known_hosts`` file), or tell the SSH client to ignore known hosts by adding 
``-o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null`` to the argument list for the ssh command above.
The full command would therefore look like:

```bash
ssh dockeruser@HOST_ADDRESS -p 2200 -o GlobalKnownHostsFile=/dev/null -o UserKnownHostsFile=/dev/null
```

The you can add a ``-Y`` flag to the ``ssh`` invocation in order to forward X11 packets between the container and your local 
environment, allowing you to use X11 graphics (e.g., for plotting in R).  This will require an X11 server (such as XQuartz
on macOS https://www.xquartz.org) to be installed on your client machine.


## 2. Connecting to R Studio in a Web Browser
Some users may prefer to use the R Studio Server IDE in a web browser instead of running R on the command line.

If you are running the web browser on the same host where the container is running, you should be able to navigate the
browser to http://localhost:8787 to access R Studio Server. You will be prompted to enter the username and password 
that were passed to the ``docker run `` command.

If you are running the web browser on a different host from the Docker host 
(e.g., running Docker on a server, connecting from a workstation/laptop), then you will need to substitute the IP address of the Docker host for ``localhost`` in the above URL.  In this latter case, you will also need to ensure that any relevant firewalls allow connections on TCP port 8787 from the "workstation" to the "server".  A full discussion of the principals of firewall configuration are beyond the scope of this document.  For further assistance, you may need to consult your local information technology team.

### Remote server with only port 22 access

Some institutions may require that network access to the Docker host
be restricted to port 22 (SSH).  In this case, clients can still connect to the R Studio Server web UI by utilizing 
SSH port forwarding. In this scenario, where the container is running on a remote "server", you
first need to initiate an SSH tunnel with the following command on the client workstation:

```bash
ssh -L 8787:DOCKER_HOST_ADDRESS:8787 USERNAME@DOCKER_HOST_ADDRESS
```

You should substitute the network address of the Docker host where the container is running in place of ``DOCKER_HOST_ADDRESS``.  
This command is invoking SSH 
to create an encrypted tunnel between TCP port 8787 on the local host to TCP port 8787 on the host at DOCKER_HOST_ADDRESS. Firewalls
do *not* need to be configured to allow TCP port 8787 to connect from the client to the server; rather, this tunnel is created over
the standard SSH port 22.  Therefore, you will also need to ensure that any relevant firewalls allow connections on TCP port 22 from the "workstation" to the "server".  A full discussion of the principals of firewall configuration are beyond the scope of this document.  For further assistance, you may need to consult your local information technology team.

For more background on how SSH tunneling works, please see: https://www.ssh.com/ssh/tunneling/example.

Note that USERNAME in the above ssh command (and the respective password that you will be prompted to enter) is the local system credential on the host that resides at DOCKER_HOST_ADDRESS, not the ephemeral container credential.

If succesful, the client should be able to visit http://localhost:8787 to see RStudio Server.

Similarly, if you are restricted to only TCP port 22 access to the Docker host, but wish to run R from the command line instead of running R Studio, you can first SSH to the Docker host (on port 22) then follow [these](##1.-Connecting-via-SSH) instructions to 
connect to the container.


## Connecting Interactively

A final option is to run the container in a way that directly presents the user with an interactive R session. The container will stop after you quit this R session. Note, this command runs the container so you can't already have one running when issuing it. The --rm flag will ensure that when the R session is quit, the container is stopped and cleaned up.

```bash
docker run --name workbench -v /SOME_LOCAL_PATH:/HostData --rm -it hmsccb/AnalyticWorkbench:latest R
```

## Connecting to SQL Server

As noted above, if the environment variables ``ACCEPT_EULA`` and ``SA_PASSWORD`` are appropriately set, an instance of SQL Server will be executed in the container.  The port mapping provided by ``-p 1433:1433`` will allow any standard SQL Server / ODBC client tools to connect to the SQL Server instance at port 1433 on the Docker host.


# Restarting R Studio Server

R Studio Utility is installed in /usr/sbin

If you need to restart rstudio server inside the container (e.g., because it becomes unresponsive)

```bash
/usr/sbin/rstudio-server restart
```