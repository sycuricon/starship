# test model
We use the model similar to C function. Firstly, we select N registers whose data is the secret data need to be spilt to memory. Then we construct the stack space to store the encrpyed result of these data. The selected registers are bounded to the encryped data in stack, if a secret data need to be computed, it must be loaded into the appointment register.

This restriction is reasonable. If we don't load $data_A$ to register A, it may be load into the $load_B$, it is equivalent to swap register A and register B and load $data_A$ to register A. (our instruction sequence is a subset of the assemble sequence of C, so if we can prove that any assemble sequence of C is a part of our construction sequence, we can say our construction is the similar to the real application.)

Then we choose three registers randomly to simulate the change of the data flow. We give the register three flag: 
- if it is bounded to a secret data in stack, it is labeled as `encrpy`
- if it is `encrpy` and the secret data has been decrpyed and loaded in this register, it is label as `plaintext`
- if it is `plaintext` and has been written when one of the source register is itself, it is labeled by `dirty`

The add operation follow the following regulations. 

1. If a source register is `encrpy` and not `plaintext`, it means we want to use the secret data to compute, when decrpy the data from stack to register. The data has flowed from stack to register. 

Someone may say: the origin data in the source register maybe skipped, but we don't case of the data has no do with the secret data, we just do this meaningless operation to change the value so that we can influence cache hit.

2. If the destination register is a normal register, we do the normal add operation.
3. If the destination regiuster is a `secret` register but it is not `plaintext`, it means that this register is used as temperature register, so we do the normal operation.
4. If the destination register is the same as the one of the source register, this add is the change the secret data, we do the normal add operation and label the register as dirty.

Someone may say, if the source register is a secret data but the destination is not a secret data, the result is still a flow of the secret data, but we can swap the register of the destination and the one of the source register, if the result can be taken place the origin data. If the result can not be taken place the origin data, we skip it is reasonably.

5. If the destination register is not same as the one of source registers and it is `dirty`, we need to spill the data from register to stack, so a encrpy happens.

the following table is the test result of the hit:

the cache entry is 16:

|hit rate |  2  |  4  |  8  |
|:--      |:---:|:---:|:---:|
|1000     |0.61 |0.63 |0.62 |
|5000     |0.62 |0.63 |0.68 |
|10000    |0.63 |0.63 |0.66 |

the cache entry is 8:

|hit rate |  2  |  4  |  8  |
|:--      |:---:|:---:|:---:|
|1000     |0.61 |0.60 |0.62 |
|5000     |0.61 |0.62 |0.59 |
|10000    |0.58 |0.60 |0.57 |

