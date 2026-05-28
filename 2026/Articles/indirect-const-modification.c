#include <stdio.h>
/* 
 * Simple, commented example howto bypass a `const` restriction using a pointer.
 */

int main() {
    const int secret_number = 100;
    
    // 1. Direct modification (This would fail to compile):
    // secret_number = 200; 

    // 2. Indirect modification:
    // We create a pointer and 'force' it to point to our constant.
    // The (int *) is a typecast that tells C: "Treat this const address as a normal one."
    int *ptr = (int *)&secret_number;

    printf("Before: %d\n", secret_number);

    // 3. Change the value via the pointer
    *ptr = 200; 

    printf("After:  %d\n", secret_number);

    return 0;
}
