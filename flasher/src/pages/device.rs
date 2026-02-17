use std::path::PathBuf;

use anyhow::Result;
use crossterm::event::{Event, KeyCode};
use ratatui::{prelude::*, widgets::{Block, Borders, List, ListState}};
use serde::Deserialize;
use tokio::process::Command;
use tracing::warn;

use crate::AppPage;

#[derive(Clone, Debug)]
pub struct DeviceInfo {
    pub path: PathBuf,
    pub pretty: String,
    pub size: u64,
}

pub struct DevicePage {
    devices: Vec<DeviceInfo>,
    cursor: usize,
    selected: Option<DeviceInfo>,
}

impl DevicePage {
    pub fn new() -> Self {
        let mut p = Self { devices: Vec::new(), cursor: 0, selected: None };
        // spawn a background refresh
        {
            let mut out = p.devices.clone();
            tokio::spawn(async move {
                if let Err(e) = refresh_devices_periodic().await {
                    warn!("device scan failed: {e:#}");
                }
            });
        }
        p
    }

    pub fn selected(&mut self) -> Option<DeviceInfo> {
        self.selected.take()
    }
}

impl Widget for &DevicePage {
    fn render(self, area: Rect, buf: &mut Buffer)
    where
        Self: Sized,
    {
        let mut state = ListState::default().with_selected(Some(self.cursor.min(self.devices.len().saturating_sub(1))));
        let items = self.devices.iter().map(|d| {
            format!("{} — {} ({})", d.path.display(), d.pretty, human_bytes(d.size))
        });
        let list = List::new(items)
            .block(Block::default().title("Select target device").borders(Borders::ALL))
            .highlight_style(Style::new().add_modifier(Modifier::REVERSED))
            .highlight_symbol(">>");

        StatefulWidget::render(list, area, buf, &mut state);
    }
}

impl AppPage for DevicePage {
    fn input(&mut self, event: Event) {
        let Event::Key(k) = event else { return };
        match k.code {
            KeyCode::Up | KeyCode::Char('k') => self.cursor = self.cursor.saturating_sub(1),
            KeyCode::Down | KeyCode::Char('j') => {
                self.cursor = (self.cursor + 1).min(self.devices.len().saturating_sub(1))
            }
            KeyCode::Enter => {
                if let Some(d) = self.devices.get(self.cursor).cloned() {
                    self.selected = Some(d);
                }
            }
            _ => (),
        }
    }

    async fn needs_update(&mut self) {
        // Simple implementation: refresh devices once when entering
        match probe_devices().await {
            Ok(devs) => {
                self.devices = devs;
                if self.cursor >= self.devices.len() && !self.devices.is_empty() {
                    self.cursor = self.devices.len().saturating_sub(1);
                }
            }
            Err(e) => warn!("failed to probe devices: {e:#}"),
        }
        // then wait forever until re-drawn or next step
        std::future::pending::<()>().await
    }
}

#[derive(Deserialize)]
struct LsblkChildren {
    name: String,
    size: Option<u64>,
    r#type: Option<String>,
    model: Option<String>,
    children: Option<Vec<LsblkChildren>>,
}

#[derive(Deserialize)]
struct LsblkOutput {
    blockdevices: Vec<LsblkChildren>,
}

async fn probe_devices() -> Result<Vec<DeviceInfo>> {
    // call lsblk -J -b -o NAME,MODEL,SIZE,TYPE
    let output = Command::new("lsblk").arg("-J").arg("-b").arg("-o").arg("NAME,MODEL,SIZE,TYPE").output().await?;
    if !output.status.success() {
        anyhow::bail!("lsblk failed");
    }
    let text = String::from_utf8_lossy(&output.stdout);
    let parsed: LsblkOutput = serde_json::from_str(&text)?;
    let mut devices = Vec::new();
    for dev in parsed.blockdevices {
        collect_disks(&dev, &mut devices);
    }
    Ok(devices)
}

fn collect_disks(node: &LsblkChildren, out: &mut Vec<DeviceInfo>) {
    if let Some(t) = &node.r#type {
        if t == "disk" {
            let name = &node.name;
            let size = node.size.unwrap_or(0);
            let pretty = node.model.clone().unwrap_or_else(|| "disk".to_string());
            out.push(DeviceInfo { path: PathBuf::from(format!("/dev/{}", name)), pretty, size });
        }
    }
    if let Some(children) = &node.children {
        for c in children {
            collect_disks(c, out);
        }
    }
}

fn human_bytes(bytes: u64) -> String {
    const KB: f64 = 1024.0;
    let mut v = bytes as f64;
    if v < KB { return format!("{} B", bytes); }
    v /= KB; if v < KB { return format!("{:.1} KiB", v); }
    v /= KB; if v < KB { return format!("{:.1} MiB", v); }
    v /= KB; if v < KB { return format!("{:.2} GiB", v); }
    v /= KB; format!("{:.2} TiB", v)
}

async fn refresh_devices_periodic() -> Result<()> {
    // refresh every 5 seconds in background — currently unused; kept for future enhancements
    loop {
        let _ = probe_devices().await;
        tokio::time::sleep(std::time::Duration::from_secs(5)).await;
    }
}
