resource "vsphere_content_library" "library" {
  name            = var.contentLibrary.name
  storage_backing = [data.vsphere_datastore.datastore.id]
  description     = var.contentLibrary.description
}

resource "vsphere_content_library_item" "avi" {
  name        = basename(var.contentLibrary.avi)
  description = basename(var.contentLibrary.avi)
  library_id  = vsphere_content_library.library.id
  file_url = var.contentLibrary.avi
}

resource "vsphere_content_library_item" "ubuntu" {
  name        = basename(var.contentLibrary.ubuntu)
  description = basename(var.contentLibrary.ubuntu)
  library_id  = vsphere_content_library.library.id
  file_url = var.contentLibrary.ubuntu
}