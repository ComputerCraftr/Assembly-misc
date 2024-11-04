#include <stdio.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h> // Include this for strerror()
#include <unistd.h>

int main()
{
    printf("arguments: %d, %d, %d, %d, %d\n", 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    // Attempt to map 4KB of memory
    void *mapped_memory = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);

    // Check if mmap succeeded
    if (mapped_memory == MAP_FAILED)
    {
        // Print the error number and corresponding error message
        printf("mmap call failed! errno: %d (%s)\n", errno, strerror(errno));
    }
    else
    {
        // mmap succeeded, print a success message
        printf("mmap call succeeded! Address: %p\n", mapped_memory);

        // Unmap the memory before exiting
        if (munmap(mapped_memory, 4096) != 0)
        {
            printf("Failed to unmap memory! errno: %d (%s)\n", errno, strerror(errno));
        }
    }

    return 0;
}
