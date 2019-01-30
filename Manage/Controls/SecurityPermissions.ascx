<%@ Control Language="VB" AutoEventWireup="false" Inherits="Intelledox.Manage.Controls_SecurityPermissions" Codebehind="SecurityPermissions.ascx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<Controls:SecureCheckBoxList ID="chkPermissions" runat="server" DataTextField="Name" DataValueField="PermissionGuid">
</Controls:SecureCheckBoxList>
