# Implementation of Akyüz and Reinhard's Nosie Reduction Technique

This program reduces noise from LDR image stack and prepares them for any HDR creation process. Also employs Reinhard et al.'s TMO and Debevec's HDR creation and CRF recovery methods for presentation purposes. All of the parts (including GUI) are implemented with MATLAB, with the help of Banterle's HDR Toolbox (which can be found in the References & Resources section.).

### Noise Reduction Method

This method reduces the noise from input LDR frames using their novel weighting function and clustering, deals better with frames that has high exposure values. A graph can be found below to give an idea how the weight function works, which is implemented in **TauFunc.m** function.

![alt text](https://github.com/varilci/HDRNoiseReduction/blob/master/readmeFiles/graphFig.png) Graph of the weight function, taken from Akyuz's paper.

### How to Run

1. Download and unzip the repo to your computer.
2. Change current directory in MATLAB to unzipped folder.
3. Add sub folders to search path
  * addpath('otherMethods')
4. Run **Akyuz_GUI.m** for GUI, run **denoise_main.m** for regular command line interaction.

![alt text](https://github.com/varilci/HDRNoiseReduction/blob/master/readmeFiles/mainGUI.png)

### Some Output Images

![alt text](https://github.com/varilci/HDRNoiseReduction/blob/master/readmeFiles/clear1.png)
Some segment of the tone mapped HDR image, created from noise reduced LDR stack.

![alt text](https://github.com/varilci/HDRNoiseReduction/blob/master/readmeFiles/regular1.png)
Some segment of the regular tone mapped HDR image, created from non-modified LDR stack.


### References

   Ahmet Oğuz Akyüz, Erik Reinhard. Noise reduction in high dynamic range imaging. Journal of Visual Communication and Image Representation, Volume 18 Issue 5, October, 2007, Pages 366-376

   Banterle, Francesco and Artusi, Alessandro and Debattista, Kurt and Chalmers, Alan. Advanced High Dynamic Range Imaging (2nd Edition), 2017. AK Peters (CRC Press)
