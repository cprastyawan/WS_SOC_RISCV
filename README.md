# Workshop SoC MRISCV
Oleh Nur Cahyo Ihsan Prastyawan\
Rabu, 15 Oktober 2025
## 1. Pendahuluan
Workshop ini diadakan untuk menguji model yang telah dibuat sejauh ini. Fokus utama dari workshop ini adalah menguji core MRISCV yang dibuat oleh Universidad Industrial de Santander (UIS) untuk dijadikan core pada SoC tipe mikrokontroler yang ingin dibuat. Panduan ini berisi langkah - langkah untuk mereplikasi sistem yang telah dilakukan sebelumnya.
## 2. Alat dan Bahan
### Software
1. Xilinx Vivado
2. Xilinx Vitis IDE
3. Serial Viewer (PuTTY, Arduino Serial Monitor, RealTerm)
### Hardware
1. Board FPGA
2. USB UART
3. Winbond W25Q128
## 3. Langkah - langkah
### Membuat Project Baru
1. Buka aplikasi Xilinx Vivado
    ![alt text](documentation/imgs/0001_buka_vivado.png)
    > Versi Xilinx Vivado yang digunakan adalah 2024.2
    
2. Klik Create New Project..., lalu klik Next
   ![Project Baru](documentation/imgs/0002_create_new_project.png)
   > Digunakan untuk membuat project baru

3. Beri nama dan lokasi project, lalu klik Next
    ![Nama Project](documentation/imgs/0003_nama_project.png)
    > Nama yang digunakan adalah workshop_soc_mriscv dengan lokasi project berada pada Vivado/Projects/

4. Pilih tipe project seperti pada gambar, lalu klik Next
    ![Tipe Project](documentation/imgs/0004_tipe_project.png)  

5. Pilih Parts/Boards yang dipakai, lalu klik Next
    ![Pilih Boards](documentation/imgs/0005_pilih_boards.png)
    > Boards/Part yang digunakan adalah Antminer S9 Board yang menggunakan chip Xilinx XC7Z010

6. Klik Finish
    ![Project Summary](documentation/imgs/0006_project_summary.png)

7. Tampilan Project Manager 
    ![Project Summary](documentation/imgs/0007_project_manager.png)

8. Pada tab sources, klik kanan pada Design Sources lalu pilih Add Sources
    ![Add Sources](documentation/imgs/0008_add_sources.png)

9. Pilih add or create design sources
    ![Add Sources](documentation/imgs/0009_add_sources_1.png)

10. Pilih add directories
    ![Add Directories](documentation/imgs/0010_add_directories.png)

11. Pilih lokasi pada folder workshop_mriscv/rtl, lalu klik Select
    ![Lokasi directory](documentation/imgs/0011_lokasi_directories.png)

12. Klik Finish
    ![Lokasi directory](documentation/imgs/0012_pilih_directories.png)

13. Pada tab IP Integrator, klik Create Block Design
    ![Membuat block design](documentation/imgs/0013_create_block_design.png)

14. Beri nama pada block design yang ingin dibuat, lalu pilih OK
    ![Nama block design](documentation/imgs/0014_nama_bd.png)

15. Tampilan Block Design akan muncul lalu klik Add IP 
    ![Add IP](documentation/imgs/0015_add_ip.png)

16. Ketik Microblaze V pada nama pencarian lalu Klik Microblaze V
    ![IP Microblaze V](documentation/imgs/0016_ip_mblazev.png)

17. Klik Run Block Automation
    ![Block Automation](documentation/imgs/0017_mblazev.png)

18. Atur opsi seperti pada gambar, lalu klik OK
    ![Microblaze V Options](documentation/imgs/0018_mblaze_block_automation.png)

19. Berikut tampilan Block Microblaze V
    ![Microblaze V Options](documentation/imgs/0019_mblaze_block.png)

### Menambahkan IP dari Vivado

20. Tambahkan IP beserta options-nya sebagai berikut:
- 1 AXI Smartconnect
    ![AXI Smartconnect](documentation/imgs/0032_smartconnect.png)
- 1 AXI BRAM Controller
    ![AXI BRAM Ctrl](documentation/imgs/0022_bram_controller.png)
- 1 Block Memory Generator
    ![Blk Mem Gen](documentation/imgs/0031_blk_mem_gen.png)
- 2 AXI GPIO
  - GPIO0
  ![GPIO 0](documentation/imgs/0020_gpio0.png)
  - GPIO1
  ![GPIO 1](documentation/imgs/0021_gpio1.png)
- 1 AXI Uartlite
  ![AXI Uartlite](documentation/imgs/0023_axi_uartlite.png)
- 1 AXI Quad SPI
    ![AXI Quad SPI 0](documentation/imgs/0026_axi_quad_spi.png)
- 2 ILA
    - ILA0
    ![ILA0](documentation/imgs/0027_ila0.png)
    - ILA1
    ![ILA1](documentation/imgs/0028_ila1.png)
- 2 Slice
  - Slice0
  ![Slice 0](documentation/imgs/0024_slice0.png)
  - Slice1 
  ![Slice 1](documentation/imgs/0025_slice1.png)
- 1 Constant
    ![Constant](documentation/imgs/0029_constant.png)
- 1 Processor System Reset
    ![Processor System Reset](documentation/imgs/0030_psr.png)

21. Hasil Board Design setelah ditambahkan seluruh IP
    ![Board Design IP](documentation/imgs/0033_ip_bd.png)

### Menambahkan module
22. Klik kanan pada tampilan board design, lalu klik Add Module
    ![Add Module](documentation/imgs/0034_add_module.png)

23. Cari module mriscvcore, lalu klik OK
    ![Add Module MRISCVCORE](documentation/imgs/0035_add_mriscvcore.png)

24. Ulangi langkah menambahkan module untuk modul berikut:
    - spi_mux
    > Module Multiplexer SPI (mux untuk AXI Quad SPI dan AXI_SPI_XIP_W25QXX)
    - axi_spi_xip_w25qxx
    > Module AXI SPI dengan mode XIP untuk menjalankan program pada winbond flash memory

25. Hasil Board Design setelah ditambahkan module
    ![Board Design Module](documentation/imgs/0036_module_done.png)

### Menyambungkan antar modul
26. Pada modul Microblaze V, klik kiri dan tahan pada port M_AXI_DP lalu geser hingga menuju modul AXI Smartconnect. Lalu sambungkan ke port S00_AXI
    ![Module wiring](documentation/imgs/0037_module_wiring.png)
27. Ulangi langkah yang sama sehingga wiring sama dengan [file berikut](documentation/pdfs/wiring_bd.pdf)

### Mengatur Port External
28. Klik kanan pada port UART dari AXI Uartlite
    ![AXI Uartlite External](documentation/imgs/0050_uartlite_make_external.png)

29. Makan tampilan AXI Uartlite menjadi seperti pada gambar
    ![AXI Uartlite With External Port](documentation/imgs/0051_uartlite_tampilan_external.png)

30. Ulangi Hal tersebut pada Port yang ditunjukkan pada tabel
    
|  Module |   Port   |
|:-------:|:--------:|
|         |  ext_sck |
|         |  ext_ss  |
| SPI Mux | ext_mosi |
|         | ext_miso |
|  GPIO0  |   GPIO   |

31.  Hasil dari port external ditunjukkan pada gambar
![AXI Uartlite With External Port](documentation/imgs/0052_port_external_result.png)

### Menambahkan clock
#### Untuk FPGA dengan Zynq7 Processing System
28. Tambahkan IP Zynq7 Processing System
    ![Processing System](documentation/imgs/0038_zynq7_ps.png)
29. Klik pada Run Block Automation, lalu atur opsi seperti pada gambar
    ![PS Options](documentation/imgs/0039_zynq7_block_automation.png)
30. Klik dua kali pada module Zynq7, lalu pada PS-PL Configuration hapus
    centang pada GP Master AXI Interface->M_AXI_GP0 Interface
    ![Uncheck GP Master AXI](documentation/imgs/0040_zynq7_options.png)
31. Pada tab Clock Configurations, ubah konfigurasi seperti pada gambar, lalu klik OK
    ![Clock Configurations](documentation/imgs/0041_clock_configurations.png)
32. Tampilan Zynq7 Processing System
    ![Tampilan PS](documentation/imgs/0042_tampilan_zynq7.png)
33. Hubungkan port yang akan dijelaskan pada tabel berikut

| Zynq7 PS |  Port Module  | Module |
|:-----:|:--------:|:------:|
| FCLK_CLK0   | Microblaze V | Clk |
| FCLK_CLK1   |  ILA0 dan ILA1 |   clk |
| FCLK_RESET0_N  | Processor System Reset | ext_reset_in |

34. Hasil block design tampak seperti pada gambar
    ![Block Design PS7](documentation/imgs/0044_wiring_1.png)

#### Untuk FPGA tanpa Zynq7 Processing System
28. Tambahkan IP Clocking Wizard
    ![Clock Wizard](documentation/imgs/0045_clock_wizard.png)
29. Klik dua kali lalu pada Clocking Options, ganti options seperti pada Gambar
    ![Clocking Options](documentation/imgs/0046_clock_wizard_2.png)
30. Hubungkan port yang akan dijelaskan pada tabel berikut
 
| Clocking Wizard |  Port Module  | Module |
|:-----:|:--------:|:------:|
| clk_out1   | Microblaze V | Clk |
| clk_out2   |  ILA0 dan ILA1 |   clk |

31. Hasil block design dengan IP Clocking Wizard
    ![Block Design Clocking Wizard](documentation/imgs/0047_clock_wizard_done.png)

32. Klik kanan pada port clk_in1 dari Clocking Wizard
    ![clk_in1](documentation/imgs/0048_clk_in1_ext.png)

33. Ulangi juga pada port resetn dari Clocking Wizard sehingga tampilan menjadi seperti pada gambar.
    ![resetn](documentation/imgs/0049_resetn_ext.png)

### Memberikan alamat untuk setiap module AXI
35. Buka tab address editor
   ![Address Editor](documentation/imgs/0053_address_editor.png)

36. Klik kanan lalu klik Assign All
   ![Assign All](documentation/imgs/0053_assign_all.png)
37. Module AXI yang telah ditetapkan alamatnya ditunjukkan pada gambar
    ![Assigned Address](documentation/imgs/0053_assigned_address.png)
38. Ganti semua address dan size-nya sesuai dengan gambar
    ![Address](documentation/imgs/0054_axi_address.png)

### Reset Pin dan Validate Design
39. Buka tab Block Design, lalu pada module Microblaze RISC-V Local Memory klik tanda '+'. Klik kanan pada pin LMB_Rst/SYS_Rst. Klik Make Connection
    ![Make Connection](documentation/imgs/0054_blk_mem_rst.png)
40. Pilih pin bus_struct_reset
    ![mb_reset](documentation/imgs/0055_mb_rst.png)
    > Hubungkan juga Debug_SYS_Rst pada Microblaze Debug Module (MDM) V dengan mb_debug_sys_rst pada Processor System Reset
42. Pada tab Design, Klik kanan pada design lalu klik Validate Design
    ![Validate Design](documentation/imgs/0056_validate_design.png)

43. Pastikan pada proses validate design tidak terdapat error atau critical warning
    ![Validate Design no error or warning](documentation/imgs/0057_no_error_warnings_validation.png)

### Membuat HDL wrapper dan generate block design
44. Pada tab Sources, klik kanan pada design lalu klik Create HDL Wrapper...
    ![HDL Wrapper](documentation/imgs/0058_membuat_wrapper.png)

45. Pilih opsi seperti pada gambar
    ![HDL Wrapper Auto Manage](documentation/imgs/0059_membuat_wrapper_auto_update.png)

46. Klik kanan pada HDL wrapper yang telah dibuat, lalu pilih Set as Top
    ![HDL Wrapper Top Level](documentation/imgs/0060_make_top_level.png)

47. Klik Generate Block Design
    ![Generate Block Design](documentation/imgs/0061_gen_blk_design.png)

48. Klik Generate
    ![Generate](documentation/imgs/0062_gen_blk_design_generate.png)

### Menambahkan constraints
49. Pada Tab Sources, klik kanan pada folder Constraints lalu klik Add Sources...
    ![Add Constraints](documentation/imgs/0063_add_constraints.png)
50. Pilih opsi Add or Create Constraints
    ![Add or Create Constraints](documentation/imgs/0064_add_constraints_options.png)
51. Klik Add Files
    ![Add or Create Constraints](documentation/imgs/0064_add_constraints_add_files.png)
52. File constraints terletak pada direktori constraints.
    ![Directory Constraints](documentation/imgs/0065_dir_constraints.png)
53. Klik Finish
    ![Constraints Finish](documentation/imgs/0066_constraints_finish.png)
54. Klik kanan pada file constraints yang telah ditambahkan, klik Set as Target Constraint File
    ![Target Constraints](documentation/imgs/0067_constraints_set_as_target.png)

55. Edit Constraints dan sesuaikan dengan port/pin board yang digunakan
    ![Edit Constraints](documentation/imgs/0093_edit_constraints.png)

### Generate Bistream
55. Klik Generate Bitstream
    ![Generate Bitstream](documentation/imgs/0067_generate_bitstream.png)
56. Klik OK untuk membuat file bitstream
    ![Generate Bitstream](documentation/imgs/0068_generate_bitstream_window.png)
57. Tunggu hingga muncul pesan seperti pada gambar, lalu pilih opsi View Reports dan klik OK
    ![Generate Bitstream Done](documentation/imgs/0069_generate_bitstream_done.png)
58. Klik tab File->Export->Export Hardware...
    ![Export Hardware](documentation/imgs/0070_export_hardware.png)
59. Klik OK
    ![Export Hardware](documentation/imgs/0071_export_hardware_1.png)
60. Pilih opsi Include Bitstream
    ![Include Bitstream](documentation/imgs/0072_include_bitstream.png)
61. Pilih nama dan lokasi dari hardware yang ingin diekspor
    ![Include Bitstream](documentation/imgs/0073_lokasi_xsa.png)
62. Klik Finish
    ![Include Bitstream](documentation/imgs/0074_xsa_finish.png)

### Vitis IDE (Membuat Platform Component)
63. Buka Vitis Unified IDE
    ![Vitis Unified IDE](documentation/imgs/0075_vitis_ide.png)

64. Klik Set Workspace...
    ![Set Workspace](documentation/imgs/0076_set_workspace.png)

65. Cari lokasi folder project Vivado, lalu buatlah folder dengan nama software. Klik Select Folder
    ![Workspace Location](documentation/imgs/0077_workspace_location.png)

66. Klik Create Platform Component
    ![Platform Component](documentation/imgs/0078_ceate_platform_component.png)

67. Beri platform nama platform-riscv
    ![Platform RISCV](documentation/imgs/0079_platform_riscv.png)

68. Klik Browse lalu pilih file .xsa yang sebelumnya telah dibuat menggunakan software Vivado. Lalu klik Next
    ![XSA Implementation](documentation/imgs/0080_xsa_implementation.png)

69. Pilih Standalone pada opsi Operating System dan microblaze riscv pada opsi Processor
    ![Operating System and Processor](documentation/imgs/0081_select_os_processor.png)

70. Klik Finish
    ![Summary](documentation/imgs/0082_riscv_summary.png)

### Vitis IDE (Membuat Application Component)
71. Klik tab File->New Component->Application
    ![Application Component](documentation/imgs/0083_application_component.png)

72. Beri nama app_loader_mriscv, lalu klik Next
    ![Application Name](documentation/imgs/0084_application_name.png)

73. Pilih platform-riscv, lalu klik Next
    ![Platform RISCV](documentation/imgs/0085_platform_riscv.png)

74. Pilih standalone_microblaze_riscv, lalu klik Next
    ![Domain](documentation/imgs/0086_domain.png)

75. Pilih Add Files
    ![Add Files](documentation/imgs/0087_add_files.png)

76. Pilih semua files yang berada pada folder software
    ![Add Files](documentation/imgs/0087_add_files_done.png)

78. Klik Finish lalu tunggu hingga selesai
    ![Finish](documentation/imgs/0088_summary.png)

### Langkah Tambahan untuk Pengguna FPGA dengan Zynq7 PS
1. Ulangi proses yang sama untuk membuat Platform. Perhatikan gambar Summary yang menunjukkan opsi apa saja yang harus disesuaikan
   ![Summary Platform ARM](documentation/imgs/0091_platform_arm.png)
   
2. Ulangi proses yang sama untuk membuat Application. Perhatikan gambar Summary yang menunjukkan opsi apa saja yang harus disesuaikan
   ![Summary Application ARM](documentation/imgs/0092_application_arm.png)

3. Build dan Run application yang telah dibuat sebelum menjalankan application app_loader_mriscv
   ![Build and Run](documentation/imgs/0093_application_arm_build_and_run.png)

### Build dan Run Application

79. Klik Build untuk mengkompilasi kode program, lalu tunggu hingga selesai
    ![Build](documentation/imgs/0089_build_app.png)

80. Klik Run untuk menjalankan program
    ![Run](documentation/imgs/0090_run_app.png)

81. Lihat output LED dan Serial melalui program Serial 

### Hasil
1. Output UART Serial
   ![UART Serial](documentation/imgs/0094_hasil_uart.png)
   ![UART Serial 2](documentation/imgs/0094_hasil_uart_2.png)

### Kompilasi Program.h
#### Software yang dibutuhkan
1. Windows Subsystem Linux
2. xPacks Dev Tools [Guide](https://xpack-dev-tools.github.io/docs/getting-started/)
3. Make

#### Langkah - Langkah
1. Buka folder firmware
   ![Folder firmware](documentation/imgs/0095_lokasi_firmware.png)
2. Klik kanan lalu klik Open In Terminal
   ![Open In Terminal](documentation/imgs/0096_open_in_terminal.png)
3. Ketik wsl lalu tekan Enter untuk masuk ke dalam environment WSL
   ![Open WSL](documentation/imgs/0096_open_wsl.png)
4. Ketik make all untuk mengkompilasi file program.h
   ![Make all](documentation/imgs/0097_make_all.png)
5. File program.h otomatis terkompilasi
   ![Program.h](documentation/imgs/0097_program.h.png)