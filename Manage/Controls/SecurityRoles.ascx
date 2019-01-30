<%@ Control Language="VB" AutoEventWireup="false" Inherits="Intelledox.Manage.Controls_SecurityRoles" Codebehind="SecurityRoles.ascx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<Controls:SecureCheckBoxList ID="chkRoles" runat="server" DataTextField="Description" DataValueField="RoleGuid">
</Controls:SecureCheckBoxList>