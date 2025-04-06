# Smart PaperMC Server Launcher 🚀

## Overview

This script automates the process of updating PaperMC and starting it with an optimal memory allocation. When running a Minecraft server in a containerized environment such as Pterodactyl, it's essential to allocate memory wisely to avoid crashes or performance issues.

![image](https://github.com/user-attachments/assets/c8bc7c9d-3b21-4b4b-bfe6-e5995a34164d)

## Why Memory Adjustment is Necessary

Minecraft servers hosted on the Pterodactyl panel must not allocate the full memory limit of the container. If the server is allowed to utilize the entirety of the container's memory:

1. **OOM Killer Activation**: The Linux Out Of Memory (OOM) killer might terminate the server process if the container runs out of memory. This happens because the server will attempt to consume all available RAM, leaving none for the host system or other processes running in the container. When the memory exceeds the limit, OOM killer shuts down the server to free up memory, resulting in a sudden crash.
   
2. **Freezes and Unresponsiveness**: In cases where the OOM killer is disabled, the server may freeze indefinitely, as the lack of memory leaves the system unable to process new requests. This can cause poor performance and eventual downtime for the server.

3. **Memory Spikes**: Minecraft can exhibit unpredictable memory usage patterns, especially with larger modpacks or many plugins, causing sudden memory spikes. Allocating slightly less than the total available memory helps accommodate these spikes without leading to crashes.

For example:
- On a 10 GB container, setting the server to use 8-8.5 GB leaves a buffer for other processes and prevents memory exhaustion.
- On smaller containers, such as a 1 GB limit, a reduction of around 400 MB helps prevent crashes while still leaving enough memory for the server to function.

### Memory Adjustment Logic

| Memory Range          | Memory Reduction         |
|-----------------------|--------------------------|
| Less than 1 GB       | Minimum of 512 MB        |
| 1 GB to 2 GB         | 10% reduction             |
| 2 GB to 4 GB         | 10% reduction             |
| 4 GB to 10 GB        | 15% reduction             |
| 10 GB and above      | 15% reduction             |

This ensures the Minecraft server always operates with a safe margin of memory, reducing the likelihood of crashes or freezes due to over-allocation.

### Script Usage

To use the script:

1. Set the container memory as the first argument (`$1`), and the Minecraft version as the second argument (`$2`).
2. The script will automatically adjust the memory allocation and start the server with optimized settings.

> [!TIP]
> If you are receiving permission errors when the server attempts to read `start.sh`, please note that you may have to update the script's file permissions manually.

#### Example

```bash
/home/container/start.sh {{SERVER_MEMORY}} {{MINECRAFT_VERSION}}
```

![image](https://github.com/user-attachments/assets/3f68023b-f01f-4f5b-93b3-bdff103b3ba9)

This command would start a Minecraft server with **4168 MB** of total memory, but only allocate **3752 MB** for Minecraft to use.

## Disclaimer

This project was created for educational purposes, with assistance from AI in writing the documentation. <br>
Please note that I am not responsible for any unintended outcomes resulting from the use of this script.

## License

This script is provided under the [MIT License](https://github.com/axtonprice/papermc-updater/blob/main/LICENSE). Feel free to modify and distribute it as needed.
