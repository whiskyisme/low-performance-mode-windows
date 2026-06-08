# Low Performance Mode - All In One

Windows low-performance mode helper by whisky.

## 支持作者 / Support

<table>
  <tr>
    <td align="center">Alipay</td>
    <td align="center">USDT TRC20</td>
  </tr>
  <tr>
    <td><img src="alipay.jpg" alt="Alipay" width="260"></td>
    <td><img src="usdt.jpg" alt="USDT TRC20" width="260"></td>
  </tr>
</table>

## 中文说明

### 这是什么

`LowPerfMode-AllInOne.bat` 是一个 Windows 批处理脚本，用来临时降低电脑性能和功耗。它会创建一个临时电源计划，把 CPU 最大性能限制到你输入的百分比，并关闭或降低部分 CPU 性能相关设置。

可选的 NVIDIA 低功耗模式会尝试通过 `nvidia-smi` 降低 NVIDIA 显卡功耗上限。如果电脑没有 NVIDIA 显卡，或驱动不支持，该步骤会自动跳过。

### 功能

- 自定义 CPU 最大性能百分比，范围 `5-100`。
- 创建临时低性能电源计划。
- 限制 CPU 最大性能。
- 关闭 CPU boost。
- 设置更省电的 CPU 能效偏好。
- 尝试降低可兼容设备的核心启用比例。
- 可选降低 NVIDIA 显卡功耗上限。
- 保存恢复状态，方便一键恢复原来的电源计划。

### 使用方法

1. 双击运行 `LowPerfMode-AllInOne.bat`。
2. 如果弹出管理员权限请求，选择允许。
3. 在菜单中选择：

```text
1. Enable extreme low-performance mode (custom CPU max %)
2. Enable extreme low-performance mode + NVIDIA low power (custom CPU max %)
3. Show status
4. Restore normal mode
0. Exit
```

4. 选择 `1` 或 `2` 后，输入 CPU 最大性能百分比，例如：

```text
5
30
100
```

输入必须是 `5-100` 的整数。输入空值、字母、小于 5 或大于 100 都会被拒绝。

### 恢复正常模式

运行脚本后选择：

```text
4. Restore normal mode
```

脚本会尝试：

- 切回启用低性能模式前的电源计划。
- 删除临时低性能电源计划。
- 恢复 NVIDIA 原功耗上限，如果之前成功修改过。
- 删除状态文件。

状态文件保存位置：

```text
%LOCALAPPDATA%\LowPerfMode\state.json
```

如果状态文件不存在，脚本会切换回 Windows Balanced 电源计划。

### 兼容性

推荐系统：

- Windows 10
- Windows 11

需要组件：

- Windows PowerShell
- `powercfg`
- 管理员权限

NVIDIA 低功耗功能还需要：

- NVIDIA 显卡
- 已安装 NVIDIA 驱动
- `nvidia-smi` 可用
- 显卡支持修改 power limit

AMD 显卡目前不会被直接限制。AMD 显卡在 Windows 上通常需要 AMD ADLX SDK 或 AMD Software 相关接口，不能直接使用 `nvidia-smi` 方式控制。

### 注意事项

- 这个脚本会明显降低电脑性能。
- 请只在自己的电脑或已获得授权的电脑上使用。
- 启用低性能模式后，如果电脑变得很慢，请重新运行脚本并选择 `4` 恢复。
- 如果恢复失败，可以在 Windows 电源设置中手动切回 Balanced 或其他常用电源计划。

## English

### What It Is

`LowPerfMode-AllInOne.bat` is a Windows batch script that temporarily lowers system performance and power usage. It creates a temporary power plan, limits the CPU maximum performance to a custom percentage, and applies several CPU power-saving settings.

The optional NVIDIA low-power mode tries to reduce the NVIDIA GPU power limit through `nvidia-smi`. If the system has no NVIDIA GPU or the driver does not support this feature, that step is skipped.

### Features

- Custom CPU maximum performance percentage from `5` to `100`.
- Temporary low-performance power plan.
- CPU maximum performance limit.
- CPU boost disabled.
- CPU energy preference set toward power saving.
- Compatible core parking settings where supported.
- Optional NVIDIA GPU power limit reduction.
- Saved state for restoring the previous power plan.

### Usage

1. Double-click `LowPerfMode-AllInOne.bat`.
2. Approve the Administrator prompt if Windows asks for it.
3. Choose an option from the menu:

```text
1. Enable extreme low-performance mode (custom CPU max %)
2. Enable extreme low-performance mode + NVIDIA low power (custom CPU max %)
3. Show status
4. Restore normal mode
0. Exit
```

4. If you choose `1` or `2`, enter a CPU maximum performance percentage:

```text
5
30
100
```

The value must be an integer from `5` to `100`. Empty input, letters, values below 5, and values above 100 are rejected.

### Restore Normal Mode

Run the script again and choose:

```text
4. Restore normal mode
```

The script will try to:

- Switch back to the power plan that was active before low-performance mode.
- Delete the temporary low-performance power plan.
- Restore the previous NVIDIA power limit if it was changed successfully.
- Delete the saved state file.

State file path:

```text
%LOCALAPPDATA%\LowPerfMode\state.json
```

If the state file does not exist, the script switches to the Windows Balanced power plan.

### Compatibility

Recommended systems:

- Windows 10
- Windows 11

Required components:

- Windows PowerShell
- `powercfg`
- Administrator permission

NVIDIA low-power mode also requires:

- NVIDIA GPU
- NVIDIA driver installed
- `nvidia-smi` available
- GPU support for changing the power limit

AMD GPUs are not directly limited by this script. On Windows, AMD GPU power tuning usually requires AMD ADLX SDK or AMD Software interfaces and cannot use the `nvidia-smi` method.

### Notes

- This script can make the computer significantly slower.
- Use it only on your own computer or on systems where you have permission.
- If the computer becomes too slow, run the script again and choose `4` to restore normal mode.
- If restore fails, manually switch back to Balanced or another normal power plan in Windows Power Options.

## License

This project is licensed under the MIT License.
