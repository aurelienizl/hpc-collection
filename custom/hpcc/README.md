# HPCC Custom Version

This custom HPCC version includes the following improvements:

1. **Code Modernization**  
    Outdated MPI function calls have been updated for compatibility.  
    Changes applied in `hpl/src/comm/HPL_packL.c`:
    ```sh
    # Backup the original file
    cp HPL_packL.c HPL_packL.c.backup

    # Update deprecated MPI functions
    sed -i 's/MPI_Address/MPI_Get_address/g' HPL_packL.c
    sed -i 's/MPI_Type_struct/MPI_Type_create_struct/g' HPL_packL.c
    ```

2. **Build Enhancement**  
    Added a dedicated `make.linux` file for streamlined compilation using the provided Dockerfile.
