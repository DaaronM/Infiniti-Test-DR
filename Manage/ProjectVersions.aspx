<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ProjectVersions" Codebehind="ProjectVersions.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>">
            </asp:Button>
        </div>
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="body">
                    <div class="msg" id="msg" runat="server" visible="false">
                    </div>
                    <Controls:PagedGridView ID="grdVersions" runat="server" Width="100%" AutoGenerateColumns="False"
                        EnableViewState="False" DataSourceID="odsVersions" PageSize="50" CssClass="grd">
                        <Columns>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, Version %>" >
                                <ItemTemplate>
                                    <asp:Label ID="lblTemplateVersion" runat="server" Text='<%# Eval("Template_Version")%>' />
                                    <asp:Image ID="imgLock" runat="server" Visible="false" ImageUrl="Images/Flag.png" ToolTip="<%$Resources:Strings, VersionInUse %>" />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, Modified %>" >
                                <ItemTemplate>
                                    <asp:LinkButton ID="lnkExport" runat="server" CommandName="Export" 
                                            CommandArgument='<%# Eval("Template_Version")%>' 
                                            Text='<% %>'/>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, ModifiedBy %>">
                                <ItemTemplate>                                    
                                    <%#:Intelledox.Manage.General.DisplayName(Eval("Modified_By"), Eval("Full_Name").ToString(), Eval("Username").ToString())%>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, Comment %>" >
                                <ItemTemplate>
                                    <asp:Label ID="lblComment" runat="server" style='white-space: pre-wrap;' Text='<%# GetComment(Eval("Comment"), Eval("Import_Date")) %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, Restore %>" Visible="false">
                                <ItemTemplate>
                                    <asp:LinkButton ID="lnkRestore" runat="server" CommandName="Restore" 
                                            CommandArgument='<%# Eval("Template_Version") %>' Text="<%$Resources:Strings, Restore %>"/>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </Controls:PagedGridView>
                    <asp:ObjectDataSource ID="odsVersions" runat="server" SelectMethod="GetProjectVersions" TypeName="Intelledox.Controller.ProjectController">
                        <SelectParameters>
                            <asp:Parameter Name="ProjectGuid" Type="Object" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>