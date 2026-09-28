export interface FileEntry {
    id: string;
    name: string;
    size: number;
    created: string;
}

export interface FileListing {
    files: FileEntry[];
    limit: number;
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
    const response = await fetch(path, init);
    if (!response.ok) {
        const body = (await response.json().catch(() => null)) as { error?: string } | null;
        throw new Error(body?.error ?? `the server answered ${response.status}`);
    }
    if (response.status === 204) return undefined as T;
    return (await response.json()) as T;
}

export function listFiles(): Promise<FileListing> {
    return request<FileListing>("/api/files");
}

export function dropFile(id: string): Promise<void> {
    return request<void>(`/api/files/${id}`, { method: "DELETE" });
}

export function downloadHref(file: FileEntry): string {
    return `/dl/${file.id}/${encodeURIComponent(file.name)}`;
}

export function need<T extends Element>(selector: string): T {
    const found = document.querySelector<T>(selector);
    if (!found) throw new Error(`the page is missing ${selector}`);
    return found;
}

export function bytes(size: number): string {
    if (size <= 0) return "0 B";
    const units = ["B", "kB", "MB", "GB", "TB"];
    const step = Math.min(Math.floor(Math.log10(size) / 3), units.length - 1);
    const value = size / 1000 ** step;
    return `${step === 0 ? value : value.toFixed(1)} ${units[step]}`;
}

export function ago(iso: string): string {
    const seconds = (Date.now() - new Date(iso).getTime()) / 1000;
    if (seconds < 90) return "just now";
    if (seconds < 3600) return `${Math.round(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.round(seconds / 3600)}h ago`;
    return `${Math.round(seconds / 86400)}d ago`;
}

// upload goes through XMLHttpRequest instead of fetch, the only way to get
// upload progress events for a large file
export function upload(file: File, onProgress: (fraction: number) => void): Promise<FileEntry> {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", "/api/files");
        xhr.upload.onprogress = (event) => {
            if (event.lengthComputable) onProgress(event.loaded / event.total);
        };
        xhr.onerror = () => reject(new Error("upload did not finish"));
        xhr.onload = () => {
            let body: { error?: string } & Partial<FileEntry> = {};
            try {
                body = JSON.parse(xhr.responseText);
            } catch {
                // the error message below covers an unparseable body too
            }
            if (xhr.status >= 200 && xhr.status < 300 && body.id) {
                resolve(body as FileEntry);
            } else {
                reject(new Error(body.error ?? `the server answered ${xhr.status}`));
            }
        };
        const form = new FormData();
        form.append("file", file, file.name);
        xhr.send(form);
    });
}
